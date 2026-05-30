extends Node

var selected_characters: Array[String] = ["Goku", "Naruto"]
var game_mode: String = "1v1"
var mode_category: String = "pvp"   # "pvp" | "ai"
var mode_submode: String  = "1v1"   # "1v1" | "2v2" | "1vAI" | "2vAI"
var is_network_game: bool = false
var local_player_id: int = 1
var last_winner: int = 1

const CHARACTER_COLORS: Dictionary = {
	"Goku": Color(1.0, 0.6, 0.1),
	"Naruto": Color(1.0, 0.7, 0.0),
	"Luffy": Color(0.9, 0.2, 0.2),
	"Conan": Color(0.2, 0.4, 0.9),
	"Doraemon": Color(0.1, 0.7, 0.9),
	"Sakura": Color(0.95, 0.5, 0.7),
	"Sasuke": Color(0.3, 0.1, 0.6),
	"Choji": Color(0.95, 0.15, 0.15),
	"Himawari": Color(0.35, 0.45, 0.9),
	"Hinata": Color(0.55, 0.35, 0.75),
	"Kakashi": Color(0.5, 0.5, 0.6),
	"Kakuzu": Color(0.25, 0.2, 0.15),
	"Kiba": Color(0.7, 0.45, 0.2),
	"Kurenai": Color(0.8, 0.15, 0.15),
	"Neji": Color(0.85, 0.8, 0.7),
	"Orochimaru": Color(0.75, 0.85, 0.45),
	"Rock Lee": Color(0.15, 0.65, 0.15),
	"Sasori": Color(0.65, 0.25, 0.15),
	"Sasuke TS": Color(0.1, 0.1, 0.35),
	"Shikadai": Color(0.5, 0.55, 0.4),
	"Shikamaru": Color(0.5, 0.45, 0.28),
	"Shino": Color(0.2, 0.35, 0.2),
	"Shino Adult": Color(0.25, 0.4, 0.25),
	"Tenten": Color(0.75, 0.42, 0.42),
	"Tsunade": Color(0.85, 0.7, 0.75),
	"Zaku": Color(0.6, 0.6, 0.65),
}

const CHARACTER_NAMES: Array[String] = [
	"Goku", "Naruto", "Luffy", "Conan", "Doraemon", "Sakura", "Sasuke",
	"Choji", "Himawari", "Hinata", "Kakashi", "Kakuzu", "Kiba", "Kurenai",
	"Neji", "Orochimaru", "Rock Lee", "Sasori", "Sasuke TS", "Shikadai",
	"Shikamaru", "Shino", "Shino Adult", "Tenten", "Tsunade", "Zaku",
]

func _ready() -> void:
	_setup_input_map()

func _setup_input_map() -> void:
	var actions := {
		"p1_left": KEY_A, "p1_right": KEY_D,
		"p1_jump": KEY_W, "p1_crouch": KEY_S,
		"p1_attack": KEY_J, "p1_special": KEY_K,
		"p1_ultimate": KEY_L, "p1_block": KEY_SHIFT,
		"p2_left": KEY_LEFT, "p2_right": KEY_RIGHT,
		"p2_jump": KEY_UP, "p2_crouch": KEY_DOWN,
		"p2_attack": KEY_KP_1, "p2_special": KEY_KP_2,
		"p2_ultimate": KEY_KP_3, "p2_block": KEY_KP_0,
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var event := InputEventKey.new()
			event.physical_keycode = actions[action_name]
			InputMap.action_add_event(action_name, event)

func go_to_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func get_input_bitmask(prefix: String) -> int:
	var bits := 0
	if Input.is_action_pressed(prefix + "left"):          bits |= 1
	if Input.is_action_pressed(prefix + "right"):         bits |= 2
	if Input.is_action_just_pressed(prefix + "jump"):     bits |= 4
	if Input.is_action_pressed(prefix + "crouch"):        bits |= 8
	if Input.is_action_just_pressed(prefix + "attack"):   bits |= 16
	if Input.is_action_just_pressed(prefix + "special"):  bits |= 32
	if Input.is_action_just_pressed(prefix + "ultimate"): bits |= 64
	if Input.is_action_pressed(prefix + "block"):         bits |= 128
	return bits
