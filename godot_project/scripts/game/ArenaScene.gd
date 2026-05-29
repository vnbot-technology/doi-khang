extends Node2D

@onready var players_node: Node2D = $Players
@onready var hud: HUD = $HUD
@onready var ground_col: CollisionShape2D = $Ground/GroundCollision

var game_manager: GameManager
var player_chars: Array[CharacterBase] = []

func _ready() -> void:
	# GroundCollision shape is now set in GameArena.tscn so we still have
	# collision even if this script errors out before reaching this point.
	# Fallback in case the scene was edited and the shape was removed.
	if ground_col.shape == null:
		ground_col.shape = WorldBoundaryShape2D.new()

	game_manager = GameManager.new()
	add_child(game_manager)
	game_manager.round_started.connect(_on_round_started)
	game_manager.round_ended.connect(_on_round_ended)
	game_manager.match_ended.connect(_on_match_ended)
	game_manager.timer_updated.connect(hud.update_timer)

	_spawn_players()

func _spawn_players() -> void:
	var chars := Global.selected_characters
	var name1 := chars[0] if chars.size() > 0 else "Goku"
	var name2 := chars[1] if chars.size() > 1 else "Naruto"

	var p1 := _create_character(name1, 1, "p1_")
	var p2 := _create_character(name2, 2, "p2_")
	players_node.add_child(p1)
	players_node.add_child(p2)
	player_chars = [p1, p2]

	p1.opponent = p2
	p2.opponent = p1

	hud.setup_players(p1, p2)
	game_manager.start_match(player_chars)

	if Global.game_mode == "2v2_ai":
		var ai := AIController.new()
		ai.difficulty = AIController.Difficulty.MEDIUM
		add_child(ai)
		ai.setup(p2)

func _create_character(char_name: String, pid: int, prefix: String) -> CharacterBase:
	var char_node: CharacterBase
	match char_name:
		"Goku":     char_node = Goku.new()
		"Naruto":   char_node = Naruto.new()
		"Luffy":    char_node = Luffy.new()
		"Conan":    char_node = Conan.new()
		"Doraemon": char_node = Doraemon.new()
		"Sakura":   char_node = Sakura.new()
		_:          char_node = Goku.new()

	var body_rect := ColorRect.new()
	body_rect.name = "BodyRect"
	body_rect.size = Vector2(50, 90)
	body_rect.position = Vector2(-25, -90)
	body_rect.color = Global.CHARACTER_COLORS.get(char_name, Color.WHITE)
	char_node.add_child(body_rect)

	var col := CollisionShape2D.new()
	var cap_shape := CapsuleShape2D.new()
	cap_shape.radius = 25.0
	cap_shape.height = 80.0
	col.shape = cap_shape
	col.position = Vector2(0, -45)
	char_node.add_child(col)

	var attack_hitbox := Hitbox.new()
	attack_hitbox.name = "AttackHitbox"
	attack_hitbox.damage = 15.0
	attack_hitbox.knockback_force = 280.0
	attack_hitbox.owner_character = char_node
	attack_hitbox.monitoring = false
	var atk_col := CollisionShape2D.new()
	var atk_shape := RectangleShape2D.new()
	atk_shape.size = Vector2(80, 50)
	atk_col.shape = atk_shape
	atk_col.position = Vector2(60, -40)
	attack_hitbox.add_child(atk_col)
	char_node.add_child(attack_hitbox)

	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.owner_character = char_node
	var hurt_col := CollisionShape2D.new()
	var hurt_cap := CapsuleShape2D.new()
	hurt_cap.radius = 28.0
	hurt_cap.height = 85.0
	hurt_col.shape = hurt_cap
	hurt_col.position = Vector2(0, -45)
	hurtbox.add_child(hurt_col)
	char_node.add_child(hurtbox)

	# Wire up node references (since char_node uses var not @onready)
	char_node.body_rect = body_rect
	char_node.attack_hitbox = attack_hitbox
	char_node.hurtbox = hurtbox

	# Set char_name before setup() so body color resolves correctly.
	# (subclass _ready() hasn't fired yet because node isn't in tree)
	char_node.char_name = char_name
	char_node.setup(pid, prefix, true)
	char_node.global_position = Vector2(300.0 if pid == 1 else 980.0, 500.0)
	return char_node

func _on_round_started(round_num: int) -> void:
	hud.show_round(round_num)

func _on_round_ended(winner_id: int) -> void:
	if winner_id > 0:
		hud.announce("PLAYER %d WINS ROUND!" % winner_id, 2.0)
	else:
		hud.announce("DRAW!", 2.0)
	hud.update_wins(
		game_manager.round_wins.get(1, 0),
		game_manager.round_wins.get(2, 0)
	)

func _on_match_ended(winner_id: int) -> void:
	Global.last_winner = winner_id
	hud.announce("PLAYER %d WINS THE MATCH!" % winner_id, 3.0)
	await get_tree().create_timer(3.5).timeout
	Global.go_to_scene("res://scenes/ResultScreen.tscn")
