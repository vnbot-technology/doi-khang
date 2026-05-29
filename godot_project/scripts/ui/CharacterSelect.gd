extends Control

# ── State ──────────────────────────────────────────────────────────────────
var _selections: Array[String] = ["", "", "", ""]  # [p1a, p1b, p2a, p2b]
var _confirmed: Array[bool]    = [false, false, false, false]

# Slots needed for current mode
# pvp 1v1  → slots 0 (P1) and 2 (P2)
# pvp 2v2  → slots 0,1 (P1 team) and 2,3 (P2 team)
# ai  1vAI → slot  0 (P1 only)
# ai  2vAI → slots 0,1 (P1 team only; AI fills 2,3)
var _active_slots: Array[int] = []

# ── Built nodes ────────────────────────────────────────────────────────────
var _start_btn: Button
var _status_labels: Array[Label] = []   # one per active slot

func _ready() -> void:
	_active_slots = _slots_for_mode()
	_build_ui()
	if Global.is_network_game:
		NetworkManager.char_pick_received.connect(_on_network_char_pick)

# ── Mode helpers ───────────────────────────────────────────────────────────

func _is_ai_mode() -> bool:
	return Global.mode_category == "ai"

func _is_2v2() -> bool:
	return Global.mode_submode in ["2v2", "2vAI"]

func _is_host() -> bool:
	return multiplayer.is_server()

func _slots_for_mode() -> Array[int]:
	var r: Array[int] = []
	if Global.is_network_game:
		if _is_host(): r.append(0) else: r.append(2)
		return r
	if _is_ai_mode():
		if _is_2v2(): r.assign([0, 1]) else: r.assign([0])
	else:
		if _is_2v2(): r.assign([0, 1, 2, 3]) else: r.assign([0, 2])
	return r

# ── UI construction ────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Header
	var header := Label.new()
	header.text = _header_text()
	header.position = Vector2(200, 22)
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	add_child(header)

	# Character panels
	if _is_2v2():
		_build_team_panels()
	else:
		_build_1v1_panels()

	# Start button — host only in online mode; hidden for client
	_start_btn = Button.new()
	_start_btn.text = "START FIGHT!"
	_start_btn.custom_minimum_size = Vector2(220, 52)
	_start_btn.add_theme_font_size_override("font_size", 22)
	_start_btn.position = Vector2(530, 660)
	_start_btn.disabled = true
	_start_btn.pressed.connect(_start_game)
	add_child(_start_btn)

	if Global.is_network_game and not _is_host():
		_start_btn.visible = false
		var wait_lbl := Label.new()
		wait_lbl.text = "Waiting for host to start..."
		wait_lbl.position = Vector2(430, 668)
		wait_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		add_child(wait_lbl)

	# Back button — return to lobby for online, main menu for offline
	var back := Button.new()
	back.text = "← Back"
	back.custom_minimum_size = Vector2(120, 40)
	back.position = Vector2(30, 670)
	if Global.is_network_game:
		back.pressed.connect(func():
			NetworkManager.disconnect_from_game()
			Global.go_to_scene("res://scenes/MainMenu.tscn")
		)
	else:
		back.pressed.connect(func(): Global.go_to_scene("res://scenes/MainMenu.tscn"))
	add_child(back)

	# Info labels
	if _is_ai_mode():
		var ai_lbl := Label.new()
		ai_lbl.text = "AI will pick automatically"
		ai_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		ai_lbl.position = Vector2(700, 90)
		add_child(ai_lbl)
	elif Global.is_network_game:
		var role := "Host (Player 1)" if _is_host() else "Client (Player 2)"
		var net_lbl := Label.new()
		net_lbl.text = "You are: " + role
		net_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		net_lbl.position = Vector2(480, 90)
		add_child(net_lbl)

func _header_text() -> String:
	match Global.mode_submode:
		"1v1":  return "⚔  PvP — 1 vs 1 — Select your fighter"
		"2v2":  return "⚔  PvP — 2 vs 2 — Each team picks 2 fighters"
		"1vAI": return "🤖  vs AI — Select your fighter"
		"2vAI": return "🤖  vs AI — Pick your 2-fighter team"
	return "Select your fighter"

func _build_1v1_panels() -> void:
	var labels := ["PLAYER 1  (WASD + J/K/L/Shift)", "PLAYER 2  (Arrows + Numpad 1/2/3/0)"]
	var x_offsets := [60, 680]
	var slot_map := [0, 2]   # panel 0 → slot 0, panel 1 → slot 2

	for i in range(2 if not _is_ai_mode() else 1):
		var slot := slot_map[i]
		_build_char_panel(x_offsets[i], 80, labels[i], slot)

func _build_team_panels() -> void:
	var team_x := [30, 650]
	var team_labels := [
		["PLAYER 1 — Fighter A", "PLAYER 1 — Fighter B"],
		["PLAYER 2 — Fighter A", "PLAYER 2 — Fighter B"],
	]
	var team_slots := [[0, 1], [2, 3]]

	for t in range(2 if not _is_ai_mode() else 1):
		for f in range(2):
			var slot := team_slots[t][f]
			var y := 80 if f == 0 else 390
			_build_char_panel(team_x[t], y, team_labels[t][f], slot)

func _build_char_panel(x: float, y: float, title: String, slot: int) -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(x, y)
	panel.add_theme_constant_override("separation", 6)
	add_child(panel)

	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 15)
	panel.add_child(lbl)

	var grid := GridContainer.new()
	grid.columns = 3
	panel.add_child(grid)

	for char_name in Global.CHARACTER_NAMES:
		var btn := Button.new()
		btn.text = char_name
		btn.custom_minimum_size = Vector2(95, 62)
		btn.pressed.connect(_select.bind(slot, char_name))
		grid.add_child(btn)

	var status := Label.new()
	status.text = "— not selected —"
	status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	panel.add_child(status)
	_status_labels.resize(max(_status_labels.size(), slot + 1))
	_status_labels[slot] = status

	var confirm := Button.new()
	confirm.text = "CONFIRM ✓"
	confirm.custom_minimum_size = Vector2(200, 42)
	confirm.pressed.connect(_confirm.bind(slot))
	panel.add_child(confirm)

# ── Selection logic ────────────────────────────────────────────────────────

func _select(slot: int, char_name: String) -> void:
	_selections[slot] = char_name
	_confirmed[slot] = false
	if slot < _status_labels.size() and is_instance_valid(_status_labels[slot]):
		_status_labels[slot].text = "Selected: " + char_name
		_status_labels[slot].add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	_refresh_start()

func _confirm(slot: int) -> void:
	if _selections[slot].is_empty():
		return
	_confirmed[slot] = true
	if slot < _status_labels.size() and is_instance_valid(_status_labels[slot]):
		_status_labels[slot].text = _selections[slot] + "  ✓"
		_status_labels[slot].add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	if Global.is_network_game:
		# Submit this player's pick to all peers via NetworkManager RPC
		NetworkManager.submit_char_pick.rpc(_selections[slot])
	_refresh_start()

func _on_network_char_pick(_peer_id: int, _char_name: String) -> void:
	# Recheck start button whenever any pick comes in (host only)
	_refresh_start()

func _network_all_picked() -> bool:
	var required := _required_online_players()
	if NetworkManager.char_picks.size() < required:
		return false
	var host_id := 1
	var all_ids := [host_id] + NetworkManager.connected_peers
	for id in all_ids:
		if not NetworkManager.char_picks.has(id):
			return false
	return true

func _required_online_players() -> int:
	return 4 if Global.mode_submode == "2v2" else 2

func _refresh_start() -> void:
	if Global.is_network_game:
		# Host can start only when ALL players have submitted a pick
		_start_btn.disabled = not (is_instance_valid(_start_btn) and _is_host() and _network_all_picked())
		return
	var ready := true
	for slot in _active_slots:
		if _selections[slot].is_empty() or not _confirmed[slot]:
			ready = false
			break
	_start_btn.disabled = not ready

# ── Start game ─────────────────────────────────────────────────────────────

func _start_game() -> void:
	if Global.is_network_game:
		_start_online()
		return

	if _is_ai_mode():
		var ai_slots := [2, 3] if _is_2v2() else [2]
		for s in ai_slots:
			_selections[s] = Global.CHARACTER_NAMES[randi() % Global.CHARACTER_NAMES.size()]

	var chars: Array[String] = []
	chars.append(_selections[0] if not _selections[0].is_empty() else "Goku")
	chars.append(_selections[2] if not _selections[2].is_empty() else "Naruto")
	Global.selected_characters = chars

	match Global.mode_submode:
		"1v1":  Global.game_mode = "1v1"
		"2v2":  Global.game_mode = "2v2_pvp"
		"1vAI": Global.game_mode = "1vAI"
		"2vAI": Global.game_mode = "2vAI"

	Global.go_to_scene("res://scenes/GameArena.tscn")

func _start_online() -> void:
	# Host collects both picks and launches
	var host_id := 1  # server always has peer id 1
	var all_ids := [host_id] + NetworkManager.connected_peers
	var picks: Array[String] = []
	for id in all_ids:
		picks.append(NetworkManager.char_picks.get(id, "Goku"))

	var char1 := picks[0] if picks.size() > 0 else "Goku"
	var char2 := picks[1] if picks.size() > 1 else "Naruto"
	var mode  := "1v1" if Global.mode_submode == "1v1" else "2v2_pvp"
	NetworkManager.sync_game_start.rpc(char1, char2, mode)
