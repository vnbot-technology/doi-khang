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

# ── Mode helpers ───────────────────────────────────────────────────────────

func _is_ai_mode() -> bool:
	return Global.mode_category == "ai"

func _is_2v2() -> bool:
	return Global.mode_submode in ["2v2", "2vAI"]

func _slots_for_mode() -> Array[int]:
	if _is_ai_mode():
		return [0, 1] if _is_2v2() else [0]
	else:
		return [0, 1, 2, 3] if _is_2v2() else [0, 2]

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

	# Start button
	_start_btn = Button.new()
	_start_btn.text = "START FIGHT!"
	_start_btn.custom_minimum_size = Vector2(220, 52)
	_start_btn.add_theme_font_size_override("font_size", 22)
	_start_btn.position = Vector2(530, 660)
	_start_btn.disabled = true
	_start_btn.pressed.connect(_start_game)
	add_child(_start_btn)

	# Back button
	var back := Button.new()
	back.text = "← Back"
	back.custom_minimum_size = Vector2(120, 40)
	back.position = Vector2(30, 670)
	back.pressed.connect(func(): Global.go_to_scene("res://scenes/MainMenu.tscn"))
	add_child(back)

	# AI info label
	if _is_ai_mode():
		var ai_lbl := Label.new()
		ai_lbl.text = "AI will pick automatically"
		ai_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		ai_lbl.position = Vector2(700, 90)
		add_child(ai_lbl)

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
	_refresh_start()

func _refresh_start() -> void:
	var ready := true
	for slot in _active_slots:
		if _selections[slot].is_empty() or not _confirmed[slot]:
			ready = false
			break
	_start_btn.disabled = not ready

# ── Start game ─────────────────────────────────────────────────────────────

func _start_game() -> void:
	if _is_ai_mode():
		# AI picks random chars for its slots
		var ai_slots := [2, 3] if _is_2v2() else [2]
		for s in ai_slots:
			_selections[s] = Global.CHARACTER_NAMES[randi() % Global.CHARACTER_NAMES.size()]

	Global.selected_characters = [
		_selections[0] if not _selections[0].is_empty() else "Goku",
		_selections[2] if not _selections[2].is_empty() else "Naruto",
	]

	match Global.mode_submode:
		"1v1":  Global.game_mode = "1v1"
		"2v2":  Global.game_mode = "2v2_pvp"
		"1vAI": Global.game_mode = "1vAI"
		"2vAI": Global.game_mode = "2vAI"

	if Global.is_network_game:
		Global.go_to_scene("res://scenes/LobbyRoom.tscn")
	else:
		Global.go_to_scene("res://scenes/GameArena.tscn")
