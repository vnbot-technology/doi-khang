extends Control

@onready var room_code_label: Label     = $RoomCodeLabel
@onready var status_label:    Label     = $StatusLabel
@onready var host_btn:        Button    = $Buttons/HostBtn
@onready var join_btn:        Button    = $Buttons/JoinBtn
@onready var join_panel:      VBoxContainer = $JoinPanel
@onready var join_input:      LineEdit  = $JoinPanel/CodeInput
@onready var join_confirm_btn: Button   = $JoinPanel/ConfirmBtn
@onready var start_btn:       Button    = $StartBtn
@onready var player_list:     VBoxContainer = $PlayerList
@onready var back_btn:        Button    = $BackBtn

func _ready() -> void:
	start_btn.disabled = true
	join_panel.hide()
	host_btn.pressed.connect(_on_host)
	join_btn.pressed.connect(func(): join_panel.show())
	join_confirm_btn.pressed.connect(_on_join_confirm)
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.connection_failed.connect(func(): status_label.text = "Connection failed!")
	NetworkManager.lan_room_discovered.connect(_on_lan_room_found)

	# Show which mode was chosen
	var mode_lbl := Label.new()
	mode_lbl.text = "Mode: %s" % Global.mode_submode
	mode_lbl.position = Vector2(540, 580)
	mode_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	add_child(mode_lbl)

func _required_players() -> int:
	return 4 if Global.mode_submode == "2v2" else 2

func _on_host() -> void:
	var err := NetworkManager.host_game()
	if err != OK:
		status_label.text = "Failed to host!"
		return
	if NetworkManager.connection_type == "lan":
		NetworkManager.start_lan_host_broadcast()
		room_code_label.text = "LAN Room — waiting for players..."
		status_label.text = "Hosting on LAN"
	else:
		var code := _generate_code()
		NetworkManager.room_code = code
		room_code_label.text = "Room Code: " + code
		status_label.text = "Share this code with your friend"
	_add_player_entry(multiplayer.get_unique_id(), "You (Host)")
	_refresh_start_btn()

func _on_join_confirm() -> void:
	var addr := join_input.text.strip_edges()
	if addr.is_empty():
		return
	status_label.text = "Connecting..."
	if NetworkManager.connection_type == "lan":
		var err := NetworkManager.join_game(addr)
		if err != OK:
			status_label.text = "Failed to connect!"
	else:
		if NetworkManager.relay_client == null:
			NetworkManager.relay_client = RelayClient.new()
			add_child(NetworkManager.relay_client)
		NetworkManager.relay_client.join_room(addr)

func _on_lan_room_found(info: Dictionary) -> void:
	join_input.text = info.get("address", "")
	status_label.text = "LAN room found — " + info.get("address", "")

func _on_start() -> void:
	if not NetworkManager.is_host:
		return
	# Sends all clients to CharacterSelect
	NetworkManager.sync_go_to_char_select.rpc()

func _on_back() -> void:
	NetworkManager.disconnect_from_game()
	Global.go_to_scene("res://scenes/MainMenu.tscn")

func _on_player_connected(id: int) -> void:
	var n := NetworkManager.get_player_count()
	_add_player_entry(id, "Player %d" % n)
	status_label.text = "%d / %d players" % [n, _required_players()]
	_refresh_start_btn()

func _on_player_disconnected(id: int) -> void:
	var node := player_list.find_child("Peer_%d" % id, false, false)
	if node:
		node.queue_free()
	var n := NetworkManager.get_player_count()
	status_label.text = "%d / %d players" % [n, _required_players()]
	_refresh_start_btn()

func _refresh_start_btn() -> void:
	if not NetworkManager.is_host:
		start_btn.disabled = true
		return
	start_btn.disabled = NetworkManager.get_player_count() < _required_players()
	if not start_btn.disabled:
		status_label.text = "Room full — host can start!"

func _add_player_entry(id: int, label_text: String) -> void:
	var lbl := Label.new()
	lbl.name = "Peer_%d" % id
	lbl.text = label_text
	player_list.add_child(lbl)

func _generate_code() -> String:
	const CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code := ""
	for i in range(6):
		code += CHARS[randi() % CHARS.length()]
	return code
