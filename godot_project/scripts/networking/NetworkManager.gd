extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed
signal server_disconnected

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var is_host: bool = false
var connection_type: String = "lan"
var room_code: String = ""
var connected_peers: Array[int] = []
var relay_client: RelayClient = null

func _ready() -> void:
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

signal lan_room_discovered(room_info: Dictionary)

func start_lan_host_broadcast() -> void:
	var broadcast := PacketPeerUDP.new()
	broadcast.set_broadcast_enabled(true)
	broadcast.set_dest_address("255.255.255.255", 7778)
	var data := JSON.stringify({"type": "host_announce", "port": DEFAULT_PORT})
	broadcast.put_packet(data.to_utf8_buffer())
	broadcast.close()
	# Re-broadcast every 2s
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_host and multiplayer.is_server():
			start_lan_host_broadcast()
	)

func scan_lan_rooms() -> void:
	discovered_rooms.clear()
	discovery_socket = PacketPeerUDP.new()
	discovery_socket.bind(7778)

func stop_lan_scan() -> void:
	if discovery_socket:
		discovery_socket.close()
		discovery_socket = null

func _process(_delta: float) -> void:
	if discovery_socket and discovery_socket.get_available_packet_count() > 0:
		var packet := discovery_socket.get_packet()
		var json_str := packet.get_string_from_utf8()
		var data: Variant = JSON.parse_string(json_str)
		if data is Dictionary and data.get("type") == "host_announce":
			var sender := discovery_socket.get_packet_ip()
			var info := {"address": sender, "port": data.get("port", DEFAULT_PORT)}
			if info not in discovered_rooms:
				discovered_rooms.append(info)
				lan_room_discovered.emit(info)

@rpc("any_peer", "call_local", "reliable")
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
