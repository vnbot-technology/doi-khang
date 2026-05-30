extends Node2D

@onready var players_node: Node2D = $Players
@onready var hud: HUD = $HUD
@onready var ground_col: CollisionShape2D = $Ground/GroundCollision

const ZOOM_NEAR   := 1.6     # max zoom-in (close combat)
const ZOOM_FAR    := 1.0     # min zoom / max zoom-out (full stage)
const DIST_NEAR   := 160.0   # player px distance → max zoom-in
const DIST_FAR    := 800.0   # player px distance → full zoom-out
const CAM_Y_BASE  := 360.0   # camera y at zoom=1.0 (full view)
const CAM_Y_NEAR  := 490.0   # camera y at zoom=ZOOM_NEAR (shows ground better)

const STAGE_BG_W := 1280.0
const STAGE_BG_H := 720.0

var game_manager: GameManager
var player_chars: Array[CharacterBase] = []
var _pause_menu: PauseMenu = null

var _camera: Camera2D = null
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _flash_overlay: ColorRect = null
var _flash_timer: float = 0.0

var _stage_file: String = "naruto.png"
var _spawn_y: float = 400.0

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
	_setup_stage()
	MusicManager.play_battle()
	_spawn_players()

func _setup_background() -> void:
	for node_name in ["SkyGlow", "Horizon"]:
		var n := get_node_or_null(node_name)
		if n: n.visible = false

	_stage_file = _pick_stage()
	var tex := load("res://assets/backgrounds/" + _stage_file) as Texture2D
	if tex == null:
		var bg := get_node_or_null("Background") as ColorRect
		if bg: bg.visible = true
		return

	var bg := get_node_or_null("Background") as ColorRect
	if bg: bg.visible = false

	# Non-uniform scale fills exactly 1280×720 so every platform level is on-screen.
	var sprite := Sprite2D.new()
	sprite.name = "StageBackground"
	sprite.texture = tex
	sprite.centered = false
	sprite.scale = Vector2(STAGE_BG_W / tex.get_width(), STAGE_BG_H / tex.get_height())
	sprite.position = Vector2.ZERO
	sprite.z_index = -100
	add_child(sprite)

func _setup_stage() -> void:
	var layout := StageLayout.get(_stage_file)
	var floor_y: float  = layout.get("floor_y",   610.0)
	var tile_color: Color = layout.get("tile_color", Color(0.4, 0.3, 0.2))
	_spawn_y = layout.get("spawn_y", 400.0)

	# Relocate the physics floor to match the stage art.
	var ground := get_node_or_null("Ground") as StaticBody2D
	if ground:
		ground.position.y = floor_y
		var gv := ground.get_node_or_null("GroundVisual") as ColorRect
		if gv:
			gv.color = tile_color
			gv.visible = true
		var fl := ground.get_node_or_null("FloorLine") as ColorRect
		if fl:
			fl.color = tile_color.lightened(0.35)

	for plat in layout.get("platforms", []):
		_spawn_platform(
			float(plat.get("x1", 0)),
			float(plat.get("x2", 1280)),
			float(plat.get("y",  300)),
			tile_color
		)

func _spawn_platform(x1: float, x2: float, y: float, color: Color) -> void:
	var width := x2 - x1
	var body := StaticBody2D.new()
	# Place body so the top surface of the 16px collision box is at y.
	body.position = Vector2((x1 + x2) * 0.5, y + 8.0)

	var col := CollisionShape2D.new()
	col.one_way_collision = true   # characters can jump through from below
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(width, 16.0)
	col.shape = rect_shape
	body.add_child(col)

	# Top highlight strip
	var top := ColorRect.new()
	top.size = Vector2(width, 8.0)
	top.position = Vector2(-width * 0.5, -8.0)
	top.color = color.lightened(0.25)
	body.add_child(top)

	# Lower body of platform tile
	var bot := ColorRect.new()
	bot.size = Vector2(width, 8.0)
	bot.position = Vector2(-width * 0.5, 0.0)
	bot.color = color.darkened(0.15)
	body.add_child(bot)

	add_child(body)

func _pick_stage() -> String:
	var chars := Global.selected_characters
	var all_chars: Array = []
	for c in chars:
		all_chars.append(c)
	var naruto_chars := ["Naruto","Sasuke","Sakura","Kakashi","Hinata","Neji","Rock Lee",
		"Shikamaru","Shikadai","Choji","Kiba","Kurenai","Shino","Shino Adult",
		"Tenten","Tsunade","Himawari","Orochimaru","Sasori","Zaku","Sasuke TS","Kakuzu"]
	var onepiece_chars := ["Luffy"]
	var db_chars := ["Goku"]
	for c in all_chars:
		if c in onepiece_chars: return "onepiece.png"
		if c in db_chars:       return "dragonball.png"
	for c in all_chars:
		if c in naruto_chars: return "naruto.png"
	return "naruto.png"

func _spawn_players() -> void:
	var chars := Global.selected_characters
	var name1 := chars[0] if chars.size() > 0 else "Goku"
	var name2 := chars[1] if chars.size() > 1 else "Naruto"

	var p1 := _create_character(name1, 1, "p1_")
	var p2 := _create_character(name2, 2, "p2_")
	players_node.add_child(p1)
	players_node.add_child(p2)
	player_chars = [p1, p2]

	# Set stage-aware spawn positions now that nodes are in the tree.
	p1.global_position = Vector2(300.0, _spawn_y)
	p2.global_position = Vector2(980.0, _spawn_y)

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

	char_node.body_rect = body_rect
	char_node.attack_hitbox = attack_hitbox
	char_node.hurtbox = hurtbox

	char_node.char_name = char_name
	char_node.setup(pid, prefix, true)
	return char_node

func _process(delta: float) -> void:
	_update_camera(delta)
	if _shake_timer > 0.0:
		_shake_timer -= delta
		_camera.offset = Vector2(
			randf_range(-1.0, 1.0) * _shake_intensity,
			randf_range(-1.0, 1.0) * _shake_intensity
		)
		if _shake_timer <= 0.0:
			_camera.offset = Vector2.ZERO
	if _flash_timer > 0.0:
		_flash_timer -= delta
		_flash_overlay.color.a = (_flash_timer / 0.25) * 0.45
		if _flash_timer <= 0.0:
			_flash_overlay.color.a = 0.0

func _update_camera(delta: float) -> void:
	if player_chars.size() < 2:
		return
	var p1 := player_chars[0]
	var p2 := player_chars[1]
	if not is_instance_valid(p1) or not is_instance_valid(p2):
		return

	var mid := (p1.global_position + p2.global_position) * 0.5
	var dist := abs(p1.global_position.x - p2.global_position.x)

	# Zoom: 1.0 (far/full view) → ZOOM_NEAR (close/zoomed in)
	var t := clamp((dist - DIST_NEAR) / (DIST_FAR - DIST_NEAR), 0.0, 1.0)
	var target_zoom := lerp(ZOOM_NEAR, ZOOM_FAR, t)
	var cur_zoom: float = lerp(_camera.zoom.x, target_zoom, delta * 3.0)
	_camera.zoom = Vector2(cur_zoom, cur_zoom)

	# Camera x: clamped within 1280px-wide background.
	# Camera y: fixed in screen-space (background extends above y=0 and sky fill
	# covers any gap, so vertical bounds are just the viewport limits).
	var half_w := 640.0 / cur_zoom
	var half_h := 360.0 / cur_zoom

	# Y shifts down a bit when zoomed in to keep the ground in frame.
	var zoom_frac := clamp((cur_zoom - ZOOM_FAR) / (ZOOM_NEAR - ZOOM_FAR), 0.0, 1.0)
	var target_y := lerp(CAM_Y_BASE, CAM_Y_NEAR, zoom_frac)
	target_y = clamp(target_y, half_h, 720.0 - half_h)

	var target_x := clamp(mid.x, half_w, STAGE_BG_W - half_w)

	var cam_pos := _camera.position
	cam_pos.x = lerp(cam_pos.x, target_x, delta * 5.0)
	cam_pos.y = lerp(cam_pos.y, target_y, delta * 3.0)
	_camera.position = cam_pos

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
	# Reset to stage spawn positions so every round starts fresh.
	if player_chars.size() >= 2:
		player_chars[0].global_position = Vector2(300.0, _spawn_y)
		player_chars[1].global_position = Vector2(980.0, _spawn_y)

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
