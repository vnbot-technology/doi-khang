extends Node2D

@onready var players_node: Node2D = $Players
@onready var hud: HUD = $HUD
@onready var ground_col: CollisionShape2D = $Ground/GroundCollision

var game_manager: GameManager
var player_chars: Array[CharacterBase] = []
var _pause_menu: PauseMenu = null

var _camera: Camera2D = null
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _flash_overlay: ColorRect = null
var _flash_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = Camera2D.new()
	_camera.position = Vector2(640, 360)
	add_child(_camera)
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 10
	add_child(flash_layer)
	_flash_overlay = ColorRect.new()
	_flash_overlay.color = Color(1, 1, 1, 0)
	_flash_overlay.size = Vector2(1280, 720)
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash_overlay)
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

	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.menu_requested.connect(_on_pause_menu)
	_pause_menu.quit_requested.connect(get_tree().quit)

	_setup_background()
	MusicManager.play_battle()
	_spawn_players()

func _setup_background() -> void:
	var tex := load("res://assets/backgrounds/stage1.png") as Texture2D
	if tex == null:
		return
	var bg_solid := get_node_or_null("Background") as ColorRect
	if bg_solid:
		bg_solid.visible = false
	# Reduce atmospheric overlays so the stage art shows through more clearly.
	var sky_glow := get_node_or_null("SkyGlow") as ColorRect
	if sky_glow:
		sky_glow.color.a = 0.12   # reduce from 0.25 to 0.12
	var horizon := get_node_or_null("Horizon") as ColorRect
	if horizon:
		horizon.color.a = 0.35   # reduce from 0.7 to 0.35
	var sprite := Sprite2D.new()
	sprite.name = "StageBackground"
	sprite.texture = tex
	sprite.centered = false
	sprite.scale = Vector2(1280.0 / tex.get_width(), 720.0 / tex.get_height())
	sprite.position = Vector2.ZERO
	sprite.z_index = -100
	add_child(sprite)

func _spawn_players() -> void:
	# NOTE: 2v2 mode is not fully implemented. Global.selected_characters may
	# contain up to 4 entries, but we currently only spawn chars[0] and chars[1].
	# When 2v2 is wired up, extend this to spawn chars[2] and chars[3] as
	# teammates and update player_chars / HUD / GameManager accordingly.
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

	p1.hit_landed.connect(_on_hit_landed.bind(p1))
	p2.hit_landed.connect(_on_hit_landed.bind(p2))
	p1.ultimate_activated.connect(_on_ultimate_activated.bind(p1))
	p2.ultimate_activated.connect(_on_ultimate_activated.bind(p2))

	hud.setup_players(p1, p2)
	game_manager.start_match(player_chars)

	if Global.game_mode in ["1vAI", "2vAI"]:
		var ai := AIController.new()
		ai.difficulty = AIController.Difficulty.MEDIUM
		add_child(ai)
		ai.setup(p2)

func _create_character(char_name: String, pid: int, prefix: String) -> CharacterBase:
	var char_node: CharacterBase
	match char_name:
		"Goku":        char_node = Goku.new()
		"Naruto":      char_node = Naruto.new()
		"Luffy":       char_node = Luffy.new()
		"Conan":       char_node = Conan.new()
		"Doraemon":    char_node = Doraemon.new()
		"Sakura":      char_node = Sakura.new()
		"Sasuke":      char_node = Sasuke.new()
		"Choji":       char_node = Choji.new()
		"Himawari":    char_node = Himawari.new()
		"Hinata":      char_node = Hinata.new()
		"Kakashi":     char_node = Kakashi.new()
		"Kakuzu":      char_node = Kakuzu.new()
		"Kiba":        char_node = Kiba.new()
		"Kurenai":     char_node = Kurenai.new()
		"Neji":        char_node = Neji.new()
		"Orochimaru":  char_node = Orochimaru.new()
		"Rock Lee":    char_node = RockLee.new()
		"Sasori":      char_node = Sasori.new()
		"Sasuke TS":   char_node = SasukeTS.new()
		"Shikadai":    char_node = Shikadai.new()
		"Shikamaru":   char_node = Shikamaru.new()
		"Shino":       char_node = Shino.new()
		"Shino Adult": char_node = ShinoAdult.new()
		"Tenten":      char_node = Tenten.new()
		"Tsunade":     char_node = Tsunade.new()
		"Zaku":        char_node = Zaku.new()
		_:             char_node = Goku.new()

	# Custom-drawn anime sprite instead of plain ColorRect.
	# Sprite draws relative to its own origin; positioning matches old ColorRect
	# bottom-center at (0,0) of the character node.
	var body_rect := CharacterSprite.new()
	body_rect.name = "BodyRect"
	body_rect.char_name = char_name
	body_rect.base_color = Global.CHARACTER_COLORS.get(char_name, Color.WHITE)
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
	atk_shape.size = Vector2(120, 60)
	atk_col.shape = atk_shape
	atk_col.position = Vector2(80, -40)
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

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var offset := Vector2(
			randf_range(-1.0, 1.0) * _shake_intensity,
			randf_range(-1.0, 1.0) * _shake_intensity
		)
		_camera.offset = offset
		if _shake_timer <= 0.0:
			_camera.offset = Vector2.ZERO
	if _flash_timer > 0.0:
		_flash_timer -= delta
		var t := _flash_timer / 0.25
		_flash_overlay.color.a = t * 0.45
		if _flash_timer <= 0.0:
			_flash_overlay.color.a = 0.0

func _on_ultimate_activated(user: CharacterBase) -> void:
	var color := Global.CHARACTER_COLORS.get(user.char_name, Color.WHITE)
	_flash_overlay.color = color
	_flash_overlay.color.a = 0.0
	_flash_timer = 0.25
	_shake_intensity = 10.0
	_shake_timer = 0.25

func _on_hit_landed(target: CharacterBase, damage: float, attacker: CharacterBase) -> void:
	var hit_pos := target.global_position + Vector2(0, -40)
	var intensity := clamp(damage / 20.0, 0.5, 2.0)
	var color := Global.CHARACTER_COLORS.get(attacker.char_name, Color.WHITE)
	HitEffect.spawn(players_node, hit_pos, color, intensity)
	if damage >= 30.0:
		_shake_intensity = clamp(damage * 0.3, 4.0, 14.0)
		_shake_timer = 0.18

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _pause_menu.visible:
			_on_pause_resume()
		else:
			_pause_menu.open()

func _on_pause_resume() -> void:
	_pause_menu.close()

func _on_pause_menu() -> void:
	_pause_menu.close()
	Global.go_to_scene("res://scenes/MainMenu.tscn")
