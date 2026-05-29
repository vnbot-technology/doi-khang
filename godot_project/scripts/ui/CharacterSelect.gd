extends Control

var _selections  = ["", "", "", ""]
var _confirmed   = [false, false, false, false]
var _active_slots = []
var _start_btn   = null
var _status_labels = []

func _ready() -> void:
	_active_slots = _compute_slots()
	_build_ui()
	if Global.is_network_game:
		NetworkManager.char_pick_received.connect(_on_network_char_pick)

func _compute_slots() -> Array:
	if Global.is_network_game:
		var r = []
		r.append(0 if multiplayer.is_server() else 2)
		return r
	if Global.mode_category == "ai":
		if Global.mode_submode in ["2v2", "2vAI"]:
			return [0, 1]
		return [0]
	else:
		if Global.mode_submode in ["2v2", "2vAI"]:
			return [0, 1, 2, 3]
		return [0, 2]

func _build_ui() -> void:
	var header = Label.new()
	header.text = _header_text()
	header.position = Vector2(200, 22)
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	add_child(header)

	if Global.mode_submode in ["2v2", "2vAI"]:
		_build_team_panels()
	else:
		_build_1v1_panels()

	_start_btn = Button.new()
	_start_btn.text = "START FIGHT!"
	_start_btn.custom_minimum_size = Vector2(220, 52)
	_start_btn.add_theme_font_size_override("font_size", 22)
	_start_btn.position = Vector2(530, 660)
	_start_btn.disabled = true
	_start_btn.pressed.connect(_start_game)
	add_child(_start_btn)

	if Global.is_network_game and not multiplayer.is_server():
		_start_btn.visible = false
		var wlbl = Label.new()
		wlbl.text = "Waiting for host to start..."
		wlbl.position = Vector2(430, 668)
		wlbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		add_child(wlbl)

	var back = Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(120, 40)
	back.position = Vector2(30, 670)
	back.pressed.connect(func(): Global.go_to_scene("res://scenes/MainMenu.tscn"))
	add_child(back)

	if Global.mode_category == "ai":
		var lbl = Label.new()
		lbl.text = "AI will pick automatically"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		lbl.position = Vector2(700, 90)
		add_child(lbl)

func _header_text() -> String:
	match Global.mode_submode:
		"1v1":  return "PvP — 1 vs 1 — Select your fighter"
		"2v2":  return "PvP — 2 vs 2 — Each team picks 2 fighters"
		"1vAI": return "vs AI — Select your fighter"
		"2vAI": return "vs AI — Pick your 2-fighter team"
	return "Select your fighter"

func _build_1v1_panels() -> void:
	var panel_count = 1 if Global.mode_category == "ai" else 2
	var labels  = ["PLAYER 1  (WASD + J/K/L/Shift)", "PLAYER 2  (Arrows + Numpad 1/2/3/0)"]
	var x_pos   = [60, 680]
	var slots   = [0, 2]
	for i in range(panel_count):
		_build_panel(x_pos[i], 80, labels[i], slots[i])

func _build_team_panels() -> void:
	var team_count = 1 if Global.mode_category == "ai" else 2
	var x_pos = [30, 650]
	var tlabels = [
		["P1 — Fighter A", "P1 — Fighter B"],
		["P2 — Fighter A", "P2 — Fighter B"],
	]
	var tslots = [[0, 1], [2, 3]]
	for t in range(team_count):
		for f in range(2):
			_build_panel(x_pos[t], 80 if f == 0 else 390, tlabels[t][f], tslots[t][f])

# Builds a character selection panel using absolute positioning.
# No VBoxContainer — avoids Godot 4.3 deferred-layout size-zero issue.
func _build_panel(x: float, y: float, title: String, slot: int) -> void:
	var lbl = Label.new()
	lbl.text = title
	lbl.position = Vector2(x, y)
	lbl.add_theme_font_size_override("font_size", 15)
	add_child(lbl)

	var btn_w = 95.0
	var btn_h = 54.0
	var gap   = 4.0
	var cols  = 3
	var row_start_y = y + 24.0

	for i in range(Global.CHARACTER_NAMES.size()):
		var cname = Global.CHARACTER_NAMES[i]
		var col = i % cols
		var row = i / cols
		var bx  = x + col * (btn_w + gap)
		var by  = row_start_y + row * (btn_h + gap)
		var btn = Button.new()
		btn.text = cname
		btn.custom_minimum_size = Vector2(btn_w, btn_h)
		btn.position = Vector2(bx, by)
		btn.pressed.connect(_select.bind(slot, cname))
		add_child(btn)

	var rows_used = ceili(float(Global.CHARACTER_NAMES.size()) / float(cols))
	var bottom_y  = row_start_y + rows_used * (btn_h + gap) + 4.0

	var status = Label.new()
	status.text = "— not selected —"
	status.position = Vector2(x, bottom_y)
	status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(status)
	while _status_labels.size() <= slot:
		_status_labels.append(null)
	_status_labels[slot] = status

	var confirm = Button.new()
	confirm.text = "CONFIRM"
	confirm.custom_minimum_size = Vector2(200, 42)
	confirm.position = Vector2(x, bottom_y + 26.0)
	confirm.pressed.connect(_confirm.bind(slot))
	add_child(confirm)

func _select(slot: int, cname: String) -> void:
	_selections[slot] = cname
	_confirmed[slot] = false
	if slot < _status_labels.size() and is_instance_valid(_status_labels[slot]):
		_status_labels[slot].text = "Selected: " + cname
		_status_labels[slot].add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	_refresh_start()

func _confirm(slot: int) -> void:
	if _selections[slot] == "":
		return
	_confirmed[slot] = true
	if slot < _status_labels.size() and is_instance_valid(_status_labels[slot]):
		_status_labels[slot].text = _selections[slot] + "  OK"
		_status_labels[slot].add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	if Global.is_network_game:
		NetworkManager.submit_char_pick.rpc(_selections[slot])
	_refresh_start()

func _on_network_char_pick(_peer_id: int, _cname: String) -> void:
	_refresh_start()

func _refresh_start() -> void:
	if not is_instance_valid(_start_btn):
		return
	if Global.is_network_game:
		_start_btn.disabled = not (multiplayer.is_server() and _network_all_picked())
		return
	for slot in _active_slots:
		if _selections[slot] == "" or not _confirmed[slot]:
			_start_btn.disabled = true
			return
	_start_btn.disabled = false

func _network_all_picked() -> bool:
	var required = 4 if Global.mode_submode == "2v2" else 2
	if NetworkManager.char_picks.size() < required:
		return false
	for id in ([1] + NetworkManager.connected_peers):
		if not NetworkManager.char_picks.has(id):
			return false
	return true

func _start_game() -> void:
	if Global.is_network_game:
		_start_online()
		return

	if Global.mode_category == "ai":
		var ai_slots = [2, 3] if Global.mode_submode in ["2v2", "2vAI"] else [2]
		for s in ai_slots:
			_selections[s] = Global.CHARACTER_NAMES[randi() % Global.CHARACTER_NAMES.size()]

	Global.selected_characters.clear()
	Global.selected_characters.append(_selections[0] if _selections[0] != "" else "Goku")
	Global.selected_characters.append(_selections[2] if _selections[2] != "" else "Naruto")

	match Global.mode_submode:
		"1v1":  Global.game_mode = "1v1"
		"2v2":  Global.game_mode = "2v2_pvp"
		"1vAI": Global.game_mode = "1vAI"
		"2vAI": Global.game_mode = "2vAI"

	Global.go_to_scene("res://scenes/GameArena.tscn")

func _start_online() -> void:
	var all_ids = [1] + NetworkManager.connected_peers
	var picks = []
	for id in all_ids:
		picks.append(NetworkManager.char_picks.get(id, "Goku"))
	var c1 = picks[0] if picks.size() > 0 else "Goku"
	var c2 = picks[1] if picks.size() > 1 else "Naruto"
	var mode = "1v1" if Global.mode_submode == "1v1" else "2v2_pvp"
	NetworkManager.sync_game_start.rpc(c1, c2, mode)
