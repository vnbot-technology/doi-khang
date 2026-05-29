extends Control

var p1_selected: String = ""
var p2_selected: String = ""

@onready var p1_grid: GridContainer = $P1Panel/Grid
@onready var p2_grid: GridContainer = $P2Panel/Grid
@onready var p1_confirmed_label: Label = $P1Panel/ConfirmedLabel
@onready var p2_confirmed_label: Label = $P2Panel/ConfirmedLabel
@onready var start_btn: Button = $StartBtn
@onready var mode_option: OptionButton = $ModeOption

func _ready() -> void:
	_populate_grids()
	$P1Panel/ConfirmBtn.pressed.connect(func(): _confirm_player(1))
	$P2Panel/ConfirmBtn.pressed.connect(func(): _confirm_player(2))
	start_btn.pressed.connect(_start_game)
	start_btn.disabled = true
	mode_option.add_item("1v1 PvP")
	mode_option.add_item("2v2 vs AI")
	mode_option.add_item("2v2 PvP")
	mode_option.select(0)

func _populate_grids() -> void:
	for char_name in Global.CHARACTER_NAMES:
		var p1_btn := Button.new()
		p1_btn.text = char_name
		p1_btn.custom_minimum_size = Vector2(100, 70)
		# Bind char_name explicitly so each button captures its own value
		# (avoids closure-capture-by-reference bug in for loops).
		p1_btn.pressed.connect(_select.bind(1, char_name))
		p1_grid.add_child(p1_btn)

		var p2_btn := Button.new()
		p2_btn.text = char_name
		p2_btn.custom_minimum_size = Vector2(100, 70)
		p2_btn.pressed.connect(_select.bind(2, char_name))
		p2_grid.add_child(p2_btn)

func _select(player_id: int, char_name: String) -> void:
	if player_id == 1:
		p1_selected = char_name
		p1_confirmed_label.text = "Selected: " + char_name
	else:
		p2_selected = char_name
		p2_confirmed_label.text = "Selected: " + char_name

func _confirm_player(player_id: int) -> void:
	var sel := p1_selected if player_id == 1 else p2_selected
	if sel.is_empty():
		return
	if player_id == 1:
		p1_confirmed_label.text = "P1: " + sel + " ✓"
	else:
		p2_confirmed_label.text = "P2: " + sel + " ✓"
	_check_ready()

func _check_ready() -> void:
	if not p1_selected.is_empty() and not p2_selected.is_empty():
		start_btn.disabled = false

func _start_game() -> void:
	Global.selected_characters = [p1_selected, p2_selected]
	# Use selected index (get_selected) rather than get_selected_id(): items
	# added via add_item(text) auto-assign IDs equal to their index, but
	# get_selected() is the unambiguous source of truth here.
	match mode_option.get_selected():
		0: Global.game_mode = "1v1"
		1: Global.game_mode = "2v2_ai"
		2: Global.game_mode = "2v2_pvp"
	if Global.is_network_game:
		Global.go_to_scene("res://scenes/LobbyRoom.tscn")
	else:
		Global.go_to_scene("res://scenes/GameArena.tscn")
