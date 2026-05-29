extends Node
class_name RelayClient

# Update RELAY_URL after deploying the relay server
const RELAY_URL := "wss://doikhang-relay.railway.app"

signal room_created(code: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal message_received(data: PackedByteArray)
signal relay_disconnected

var ws := WebSocketPeer.new()
var room_code_local: String = ""
var connected: bool = false
var _pending_action: String = ""

func create_room() -> void:
	_pending_action = "create"
	_connect_ws()

func join_room(code: String) -> void:
	room_code_local = code
	_pending_action = "join"
	_connect_ws()

func _connect_ws() -> void:
	var err := ws.connect_to_url(RELAY_URL)
	if err != OK:
		push_error("Relay WS connect error: " + error_string(err))

func _process(_delta: float) -> void:
	ws.poll()
	var ws_state := ws.get_ready_state()
	match ws_state:
		WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				_execute_pending()
			while ws.get_available_packet_count() > 0:
				_handle_packet(ws.get_packet())
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				relay_disconnected.emit()

func _execute_pending() -> void:
	match _pending_action:
		"create": _send_json({"action": "create"})
		"join":   _send_json({"action": "join", "code": room_code_local})
	_pending_action = ""

func _handle_packet(packet: PackedByteArray) -> void:
	var text := packet.get_string_from_utf8()
	var msg: Variant = JSON.parse_string(text)
	if not (msg is Dictionary):
		message_received.emit(packet)
		return
	match msg.get("type", ""):
		"room_created":
			room_code_local = msg.get("code", "")
			NetworkManager.room_code = room_code_local
			room_created.emit(room_code_local)
		"joined":
			room_code_local = msg.get("code", "")
			NetworkManager.room_code = room_code_local
		"peer_joined":
			var pid: int = msg.get("peer_id", 0)
			peer_joined.emit(pid)
		"peer_left":
			var pid: int = msg.get("peer_id", 0)
			peer_left.emit(pid)
		"relay":
			var hex_data: String = msg.get("data", "")
			if not hex_data.is_empty():
				message_received.emit(hex_data.hex_decode())

func send_to_peer(data: PackedByteArray) -> void:
	if not connected:
		return
	_send_json({"action": "relay", "room": room_code_local, "data": data.hex_encode()})

func disconnect_relay() -> void:
	ws.close()
	connected = false

func _send_json(obj: Dictionary) -> void:
	ws.send_text(JSON.stringify(obj))
