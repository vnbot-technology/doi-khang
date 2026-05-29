extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed
signal server_disconnected
signal char_pick_received(peer_id: int, char_name: String)

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var is_host: bool = false
var connection_type: String = "lan"
var room_code: String = ""
var connected_peers: Array[int] = []
var relay_client: RelayClient = null
var char_picks: Dictionary = {}   # peer_id → char_name

func _ready() -> void:
	set_process(false)  # only enable while scanning LAN
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Server create failed: " + error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_host = true
	connected_peers.clear()
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Client connect failed: " + error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_host = false
	return OK

func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	connected_peers.clear()
	is_host = false

func get_player_count() -> int:
	return connected_peers.size() + (1 if multiplayer.is_server() else 0)

# LAN discovery
var udp_server: UDPServer = null
var discovery_socket: PacketPeerUDP = null
var discovered_rooms: Array[Dictionary] = []
var _lan_broadcast_active: bool = false

signal lan_room_discovered(room_info: Dictionary)

func start_lan_host_broadcast() -> void:
	# Guard against duplicate recursive timer chains
	if _lan_broadcast_active:
		return
	_lan_broadcast_active = true
	_lan_broadcast_tick()

func _lan_broadcast_tick() -> void:
	# Stop chain if no longer hosting
	if not (is_host and multiplayer.is_server()):
		_lan_broadcast_active = false
		return
	var broadcast := PacketPeerUDP.new()
	# Bind to ephemeral port first so broadcasting works on all platforms
	var bind_err := broadcast.bind(0)
	if bind_err == OK:
		broadcast.set_broadcast_enabled(true)
		broadcast.set_dest_address("255.255.255.255", 7778)
		var data := JSON.stringify({"type": "host_announce", "port": DEFAULT_PORT})
		var put_err := broadcast.put_packet(data.to_utf8_buffer())
		if put_err != OK:
			push_warning("LAN broadcast failed: " + error_string(put_err))
	else:
		push_warning("LAN broadcast bind failed: " + error_string(bind_err))
	broadcast.close()
	# Re-broadcast every 2s using a single chained timer
	get_tree().create_timer(2.0).timeout.connect(_lan_broadcast_tick)

func scan_lan_rooms() -> void:
	discovered_rooms.clear()
	if discovery_socket:
		discovery_socket.close()
	discovery_socket = PacketPeerUDP.new()
	var err := discovery_socket.bind(7778)
	if err != OK:
		push_error("LAN scan bind failed: " + error_string(err))
		discovery_socket = null
		return
	set_process(true)

func stop_lan_scan() -> void:
	if discovery_socket:
		discovery_socket.close()
		discovery_socket = null
	set_process(false)

func _process(_delta: float) -> void:
	if discovery_socket == null:
		set_process(false)
		return
	if discovery_socket.get_available_packet_count() > 0:
		var packet := discovery_socket.get_packet()
		var json_str := packet.get_string_from_utf8()
		var data: Variant = JSON.parse_string(json_str)
		if data is Dictionary and data.get("type") == "host_announce":
			var sender := discovery_socket.get_packet_ip()
			var info := {"address": sender, "port": data.get("port", DEFAULT_PORT)}
			if info not in discovered_rooms:
				discovered_rooms.append(info)
				lan_room_discovered.emit(info)

@rpc("authority", "call_local", "reliable")
func sync_go_to_char_select() -> void:
	char_picks.clear()
	Global.go_to_scene("res://scenes/CharacterSelect.tscn")

# Called by each client to submit their character choice to the host.
@rpc("any_peer", "call_local", "reliable")
func submit_char_pick(char_name: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = multiplayer.get_unique_id()
	char_picks[sender] = char_name
	char_pick_received.emit(sender, char_name)

@rpc("authority", "call_local", "reliable")
func sync_game_start(char1: String, char2: String, mode: String) -> void:
	Global.selected_characters = [char1, char2]
	Global.game_mode = mode
	Global.go_to_scene("res://scenes/GameArena.tscn")

func _on_peer_connected(id: int) -> void:
	connected_peers.append(id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	player_connected.emit(multiplayer.get_unique_id())

func _on_connection_failed() -> void:
	connection_failed.emit()

func _on_server_disconnected() -> void:
	disconnect_from_game()
	server_disconnected.emit()
