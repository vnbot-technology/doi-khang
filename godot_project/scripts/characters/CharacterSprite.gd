extends Node2D
class_name CharacterSprite

# Custom-drawn anime-style fighter sprite. Replaces the placeholder ColorRect
# previously used as the character "body". Each character has its own signature
# silhouette (hair, outfit, accessories) so they're recognizable at a glance.

var char_name: String = ""
var base_color: Color = Color.WHITE
var is_hurt: bool = false
var is_attacking: bool = false
var is_blocking: bool = false
var is_dead: bool = false
var flash_color: Color = Color.TRANSPARENT
var _flash_timer: float = 0.0

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			flash_color = Color.TRANSPARENT
	queue_redraw()

func flash(color: Color, duration: float) -> void:
	flash_color = color
	_flash_timer = duration

func _draw() -> void:
	var c: Color = flash_color if _flash_timer > 0.0 else base_color
	var dark: Color = c.darkened(0.35)
	var light: Color = c.lightened(0.3)

	if is_dead:
		_draw_dead(c)
		return

	# Soft aura behind character
	draw_circle(Vector2(0, -50), 38, Color(c.r, c.g, c.b, 0.12))

	# Ground shadow
	_draw_ellipse(Vector2(0, -2), Vector2(28, 7), Color(0, 0, 0, 0.3))

	match char_name:
		"Goku":     _draw_goku(c, dark, light)
		"Naruto":   _draw_naruto(c, dark, light)
		"Luffy":    _draw_luffy(c, dark, light)
		"Conan":    _draw_conan(c, dark, light)
		"Doraemon": _draw_doraemon(c, dark, light)
		"Sakura":   _draw_sakura(c, dark, light)
		_:          _draw_generic(c, dark, light)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle: float = i * TAU / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _draw_dead(c: Color) -> void:
	# Fallen pose: flat horizontal silhouette
	_draw_ellipse(Vector2(0, -8), Vector2(38, 10), c.darkened(0.4))
	draw_circle(Vector2(-30, -8), 12, c.lightened(0.2))
	# X eyes
	draw_line(Vector2(-34, -12), Vector2(-28, -6), Color.BLACK, 2)
	draw_line(Vector2(-28, -12), Vector2(-34, -6), Color.BLACK, 2)
	draw_line(Vector2(-26, -12), Vector2(-22, -6), Color.BLACK, 2)
	draw_line(Vector2(-22, -12), Vector2(-26, -6), Color.BLACK, 2)

func _body_lean() -> float:
	return 6.0 if is_attacking else 0.0

# ── EYES ────────────────────────────────────────────────────
func _draw_eyes(head_pos: Vector2, _c: Color) -> void:
	draw_circle(head_pos + Vector2(-5, -2), 3.5, Color.WHITE)
	draw_circle(head_pos + Vector2(5, -2), 3.5, Color.WHITE)
	draw_circle(head_pos + Vector2(-5, -2), 2, Color.BLACK)
	draw_circle(head_pos + Vector2(5, -2), 2, Color.BLACK)
	# Shine
	draw_circle(head_pos + Vector2(-4, -3), 1, Color.WHITE)
	draw_circle(head_pos + Vector2(6, -3), 1, Color.WHITE)

func _draw_slash_effect(pos: Vector2, c: Color) -> void:
	var slash_color := Color(c.r, c.g, c.b, 0.7).lightened(0.4)
	draw_line(pos + Vector2(-15, -20), pos + Vector2(20, 15), slash_color, 4)
	draw_line(pos + Vector2(-20, -10), pos + Vector2(15, 20), slash_color, 3)
	draw_circle(pos, 8, Color(1, 1, 0.8, 0.5))

# ── GENERIC FIGHTER ─────────────────────────────────────────
func _draw_generic(c: Color, dark: Color, light: Color) -> void:
	var lean: float = _body_lean()
	# Legs
	draw_rect(Rect2(-14 + lean * 0.3, -32, 11, 32), dark)
	draw_rect(Rect2(3 + lean * 0.3, -32, 11, 32), dark)
	# Body
	draw_rect(Rect2(-13 + lean, -72, 26, 42), c)
	# Head
	draw_circle(Vector2(lean, -82), 14, light)
	_draw_eyes(Vector2(lean, -82), c)
	# Arms in fighting stance
	if is_blocking:
		draw_line(Vector2(-13 + lean, -62), Vector2(-22 + lean, -48), dark, 7)
		draw_line(Vector2(13 + lean, -62), Vector2(22 + lean, -48), dark, 7)
	else:
		draw_line(Vector2(-13 + lean, -62), Vector2(-28 + lean, -50), dark, 7)
		draw_line(Vector2(13 + lean, -62), Vector2(32 + lean, -44), c, 7)
	if is_attacking:
		_draw_slash_effect(Vector2(40, -50), c)

# ── GOKU (Dragon Ball) ──────────────────────────────────────
func _draw_goku(c: Color, _dark: Color, _light: Color) -> void:
	var lean: float = _body_lean()
	var skin := Color(0.95, 0.85, 0.7)
	# Gi pants (darker orange/brown)
	draw_rect(Rect2(-14 + lean * 0.3, -32, 11, 32), Color(0.6, 0.3, 0.05))
	draw_rect(Rect2(3 + lean * 0.3, -32, 11, 32), Color(0.6, 0.3, 0.05))
	# Orange gi body
	draw_rect(Rect2(-14 + lean, -72, 28, 42), c)
	# Blue belt
	draw_rect(Rect2(-14 + lean, -36, 28, 6), Color(0.2, 0.2, 0.7))
	# Head
	draw_circle(Vector2(lean, -83), 14, skin)
	_draw_eyes(Vector2(lean, -83), Color(0.1, 0.1, 0.4))
	# Spiky black hair (signature)
	var hair_base := Vector2(lean, -83)
	var hair_color := Color(0.1, 0.1, 0.1)
	var spikes := [
		Vector2(-6, -14), Vector2(0, -17), Vector2(6, -14),
		Vector2(10, -10), Vector2(-10, -10), Vector2(3, -15), Vector2(-3, -15)
	]
	for sp in spikes:
		draw_line(hair_base + sp * 0.5, hair_base + sp, hair_color, 3)
	# Side hair
	draw_rect(Rect2(lean - 16, -96, 8, 18), hair_color)
	draw_rect(Rect2(lean + 8, -96, 8, 18), hair_color)
	# Arms
	draw_line(Vector2(-14 + lean, -62), Vector2(-30 + lean, -50), skin, 8)
	draw_line(Vector2(14 + lean, -62), Vector2(34 + lean, -44), skin, 8)
	if is_attacking:
		_draw_slash_effect(Vector2(44, -48), Color(1.0, 0.9, 0.2))
		# Kamehameha glow hint
		draw_circle(Vector2(44 + lean, -44), 10, Color(0.3, 0.5, 1.0, 0.6))

# ── NARUTO ──────────────────────────────────────────────────
func _draw_naruto(c: Color, _dark: Color, _light: Color) -> void:
	var lean: float = _body_lean()
	var skin := Color(0.95, 0.82, 0.65)
	# Orange jumpsuit
	draw_rect(Rect2(-13 + lean * 0.3, -32, 11, 32), c)
	draw_rect(Rect2(3 + lean * 0.3, -32, 11, 32), c)
	draw_rect(Rect2(-13 + lean, -72, 26, 42), c)
	# Blue shoulder stripe
	draw_rect(Rect2(-13 + lean, -72, 26, 5), Color(0.2, 0.3, 0.8))
	# Head
	draw_circle(Vector2(lean, -83), 13, skin)
	_draw_eyes(Vector2(lean, -83), Color(0.0, 0.3, 0.8))
	# Whisker marks
	var face := Vector2(lean, -83)
	draw_line(face + Vector2(-11, -2), face + Vector2(-4, 0), Color(0.6, 0.4, 0.2), 2)
	draw_line(face + Vector2(-11, 2), face + Vector2(-4, 3), Color(0.6, 0.4, 0.2), 2)
	draw_line(face + Vector2(4, -2), face + Vector2(11, 0), Color(0.6, 0.4, 0.2), 2)
	draw_line(face + Vector2(4, 2), face + Vector2(11, 3), Color(0.6, 0.4, 0.2), 2)
	# Headband
	draw_rect(Rect2(lean - 14, -98, 28, 8), Color(0.2, 0.2, 0.7))
	draw_rect(Rect2(lean - 6, -99, 12, 4), Color(0.8, 0.8, 0.9))
	# Spiky blonde hair sticking out below headband
	draw_line(Vector2(lean - 12, -90), Vector2(lean - 14, -94), Color(1.0, 0.85, 0.2), 3)
	draw_line(Vector2(lean - 4, -90), Vector2(lean - 6, -95), Color(1.0, 0.85, 0.2), 3)
	draw_line(Vector2(lean + 4, -90), Vector2(lean + 6, -95), Color(1.0, 0.85, 0.2), 3)
	draw_line(Vector2(lean + 12, -90), Vector2(lean + 14, -94), Color(1.0, 0.85, 0.2), 3)
	# Arms
	draw_line(Vector2(-13 + lean, -62), Vector2(-28 + lean, -48), skin, 8)
	draw_line(Vector2(13 + lean, -62), Vector2(32 + lean, -42), skin, 8)
	if is_attacking:
		_draw_slash_effect(Vector2(42, -46), Color(1, 0.95, 0.3))

# ── LUFFY ───────────────────────────────────────────────────
func _draw_luffy(c: Color, _dark: Color, _light: Color) -> void:
	var lean: float = _body_lean()
	var skin := Color(0.95, 0.82, 0.65)
	# Dark shorts
	draw_rect(Rect2(-13 + lean * 0.3, -32, 11, 32), Color(0.3, 0.3, 0.3))
	draw_rect(Rect2(3 + lean * 0.3, -32, 11, 32), Color(0.3, 0.3, 0.3))
	# Red vest body
	draw_rect(Rect2(-13 + lean, -72, 26, 42), c)
	# Open vest reveals skin in middle
	draw_rect(Rect2(-6 + lean, -72, 12, 38), skin)
	draw_line(Vector2(0 + lean, -72), Vector2(0 + lean, -34), Color(0.4, 0.1, 0.1), 2)
	# Head
	draw_circle(Vector2(lean, -83), 13, skin)
	_draw_eyes(Vector2(lean, -83), Color(0.15, 0.1, 0.05))
	# Straw hat (signature)
	var hat_c := Color(0.85, 0.70, 0.3)
	_draw_ellipse(Vector2(lean, -95), Vector2(20, 5), hat_c)
	draw_rect(Rect2(-10 + lean, -103, 20, 12), hat_c)
	# Red ribbon
	draw_rect(Rect2(-10 + lean, -94, 20, 3), Color(0.9, 0.1, 0.1))
	# X scar under left eye
	draw_line(Vector2(3 + lean, -84), Vector2(7 + lean, -80), Color(0.6, 0.1, 0.1), 2)
	draw_line(Vector2(7 + lean, -84), Vector2(3 + lean, -80), Color(0.6, 0.1, 0.1), 2)
	# Arms (rubber stretch when attacking)
	if is_attacking:
		draw_line(Vector2(13 + lean, -62), Vector2(55 + lean, -40), skin, 7)
		_draw_slash_effect(Vector2(58, -44), Color(1, 0.4, 0.4))
	else:
		draw_line(Vector2(-13 + lean, -62), Vector2(-28 + lean, -50), skin, 8)
		draw_line(Vector2(13 + lean, -62), Vector2(32 + lean, -44), skin, 8)

# ── CONAN ───────────────────────────────────────────────────
func _draw_conan(c: Color, _dark: Color, _light: Color) -> void:
	var lean: float = _body_lean()
	var skin := Color(0.95, 0.82, 0.65)
	# Kid-proportioned legs
	draw_rect(Rect2(-10 + lean * 0.3, -26, 9, 26), c)
	draw_rect(Rect2(1 + lean * 0.3, -26, 9, 26), c)
	# Body/jacket
	draw_rect(Rect2(-11 + lean, -60, 22, 36), c)
	# Red bow tie
	draw_circle(Vector2(lean, -50), 5, Color(0.9, 0.1, 0.1))
	# Head (oversized = kid)
	draw_circle(Vector2(lean, -73), 15, skin)
	_draw_eyes(Vector2(lean, -73), Color(0.05, 0.1, 0.6))
	# Glasses (signature)
	var gc := Color(0.3, 0.3, 0.8)
	draw_arc(Vector2(lean - 7, -73), 5, 0, TAU, 16, gc, 2)
	draw_arc(Vector2(lean + 7, -73), 5, 0, TAU, 16, gc, 2)
	draw_line(Vector2(lean - 2, -73), Vector2(lean + 2, -73), gc, 2)
	draw_line(Vector2(lean - 12, -73), Vector2(lean - 15, -73), gc, 2)
	# Black side-part hair
	draw_rect(Rect2(lean - 15, -89, 30, 10), Color(0.08, 0.08, 0.08))
	# Arms
	draw_line(Vector2(-11 + lean, -55), Vector2(-24 + lean, -44), skin, 7)
	draw_line(Vector2(11 + lean, -55), Vector2(27 + lean, -38), skin, 7)
	if is_attacking:
		# Soccer ball kick
		draw_circle(Vector2(35 + lean, -20), 10, Color(1, 1, 1))
		draw_arc(Vector2(35 + lean, -20), 10, 0, TAU, 8, Color(0.2, 0.2, 0.2), 2)
		_draw_slash_effect(Vector2(38, -20), Color(0.2, 0.4, 1))

# ── DORAEMON ────────────────────────────────────────────────
func _draw_doraemon(c: Color, _dark: Color, _light: Color) -> void:
	var lean: float = _body_lean()
	# Round blue body
	_draw_ellipse(Vector2(lean, -38), Vector2(22, 38), c)
	# White belly
	_draw_ellipse(Vector2(lean, -34), Vector2(16, 28), Color.WHITE)
	# Pocket
	draw_rect(Rect2(-10 + lean, -42, 20, 14), Color(0.85, 0.85, 0.85))
	draw_arc(Vector2(lean, -42), 10, 0, PI, 16, Color(0.6, 0.6, 0.6), 2)
	# Big round head
	draw_circle(Vector2(lean, -78), 22, c)
	# White face
	draw_circle(Vector2(lean, -74), 16, Color.WHITE)
	_draw_eyes(Vector2(lean - 2, -79), Color(0.05, 0.05, 0.05))
	# Red nose
	draw_circle(Vector2(lean, -70), 5, Color(0.9, 0.1, 0.1))
	# Mouth line
	draw_line(Vector2(lean - 12, -66), Vector2(lean + 12, -66), Color(0.3, 0.3, 0.3), 2)
	# Cat whiskers
	draw_line(Vector2(lean - 5, -68), Vector2(lean - 20, -65), Color(0.3, 0.3, 0.3), 1)
	draw_line(Vector2(lean - 5, -66), Vector2(lean - 20, -66), Color(0.3, 0.3, 0.3), 1)
	draw_line(Vector2(lean + 5, -68), Vector2(lean + 20, -65), Color(0.3, 0.3, 0.3), 1)
	draw_line(Vector2(lean + 5, -66), Vector2(lean + 20, -66), Color(0.3, 0.3, 0.3), 1)
	# Red collar + bell
	draw_rect(Rect2(-22 + lean, -60, 44, 6), Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(lean, -56), 4, Color(1, 0.9, 0))
	# Stubby arms
	_draw_ellipse(Vector2(-24 + lean, -50), Vector2(8, 6), c)
	_draw_ellipse(Vector2(24 + lean, -50), Vector2(8, 6), c)
	if is_attacking:
		# Gadget flash from pocket
		draw_circle(Vector2(lean, -42), 14, Color(1, 1, 0.5, 0.7))
		_draw_slash_effect(Vector2(30, -42), Color(0.1, 0.7, 0.9))

# ── SAKURA ──────────────────────────────────────────────────
func _draw_sakura(c: Color, _dark: Color, _light: Color) -> void:
	var lean: float = _body_lean()
	var skin := Color(0.95, 0.82, 0.65)
	# Dark pants
	draw_rect(Rect2(-12 + lean * 0.3, -32, 10, 32), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(2 + lean * 0.3, -32, 10, 32), Color(0.15, 0.15, 0.15))
	# Red top
	draw_rect(Rect2(-12 + lean, -68, 24, 38), c)
	# White inner shirt collar
	draw_rect(Rect2(-7 + lean, -68, 14, 6), Color(0.95, 0.95, 0.95))
	# Pink hair behind head
	var hair_c := Color(0.98, 0.4, 0.65)
	draw_circle(Vector2(lean, -82), 15, hair_c)
	# Head over hair
	draw_circle(Vector2(lean, -80), 13, skin)
	_draw_eyes(Vector2(lean, -80), Color(0.1, 0.5, 0.2))
	# Red hair band
	draw_rect(Rect2(lean - 15, -90, 30, 5), Color(0.8, 0.1, 0.3))
	# Long hair strands
	draw_line(Vector2(lean - 10, -82), Vector2(lean - 16, -50), hair_c, 6)
	draw_line(Vector2(lean + 10, -82), Vector2(lean + 16, -50), hair_c, 5)
	# Forehead diamond mark (subtle nod to her Byakugou)
	draw_circle(Vector2(lean, -88), 1.5, Color(0.7, 0.2, 0.4))
	# Arms
	draw_line(Vector2(-12 + lean, -60), Vector2(-26 + lean, -46), skin, 8)
	draw_line(Vector2(12 + lean, -60), Vector2(28 + lean, -40), skin, 8)
	if is_attacking:
		# Ground punch shockwave
		draw_line(Vector2(-20 + lean, -5), Vector2(20 + lean, -5), Color(0.9, 0.8, 0.95), 4)
		draw_line(Vector2(-30 + lean, 0), Vector2(30 + lean, 0), Color(0.8, 0.6, 0.9, 0.7), 6)
		_draw_slash_effect(Vector2(32, -44), Color(0.98, 0.4, 0.65))
