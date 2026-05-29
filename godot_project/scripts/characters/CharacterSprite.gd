extends Node2D
class_name CharacterSprite

# Pixel-art renderer. Delegates frame data to per-character static classes
# (PixelGoku, PixelNaruto, …) located in scripts/characters/sprites/.
# Each art pixel is rendered as a PX×PX screen-pixel rectangle via draw_rect().
# PNG characters (e.g. Sasuke) load a spritesheet and use draw_texture_rect_region().

const PX := 3           # screen pixels per art pixel → 60×96 px sprite on screen
const SPRITE_W := 20    # art pixels wide (all characters use the same grid)

# PNG spritesheet paths keyed by char_name
const PNG_SPRITE_PATHS: Dictionary = {
	"Sasuke": "res://assets/sprites/sasuke_sheet.png",
}

# Per-character frame regions (Rect2) keyed by animation state name.
# Auto-detected bounding boxes from white-background spritesheet.
# Scale PNG_SCALE is applied at draw time.
const PNG_FRAME_DATA: Dictionary = {
	"Sasuke": {
		"idle0":  [Rect2(255,  55, 47, 46)],
		"idle1":  [Rect2(255,  55, 47, 46)],
		"walk0":  [Rect2( 30, 294, 35, 47)],
		"walk1":  [Rect2(152, 295, 34, 45)],
		"jump":   [Rect2(616, 153, 47, 51)],
		"attack": [Rect2(621,  31, 92, 70)],
		"block":  [Rect2(378,  56, 43, 45)],
		"hurt":   [Rect2(735, 174, 51, 47)],
		"dead":   [Rect2(862, 199, 47, 23)],
	}
}

const PNG_SCALE := 2.0   # render PNG frames at 2× (walk frames ~47px → ~94px tall)

var _png_texture: Texture2D = null

func _ready() -> void:
	if char_name in PNG_SPRITE_PATHS:
		_png_texture = load(PNG_SPRITE_PATHS[char_name]) as Texture2D

var char_name: String = ""
var base_color: Color = Color.WHITE  # kept for API compatibility
var is_attacking: bool = false
var is_blocking: bool = false
var is_dead: bool = false
var is_walking: bool = false
var is_jumping: bool = false
var is_hurt: bool = false
var flash_color: Color = Color.TRANSPARENT
var _flash_timer: float = 0.0
var _anim_tick: int = 0
var _anim_timer: float = 0.0
var _walk_tick: int = 0
var _walk_timer: float = 0.0

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			flash_color = Color.TRANSPARENT
	_anim_timer += delta
	if _anim_timer >= 0.45:
		_anim_timer = 0.0
		_anim_tick = (_anim_tick + 1) % 2
	if is_walking:
		_walk_timer += delta
		if _walk_timer >= 0.18:
			_walk_timer = 0.0
			_walk_tick = (_walk_tick + 1) % 2
	else:
		_walk_timer = 0.0
	queue_redraw()

func flash(color: Color, duration: float) -> void:
	flash_color = color
	_flash_timer = duration

func _draw() -> void:
	var sk: String
	if is_dead:        sk = "dead"
	elif is_attacking: sk = "attack"
	elif is_blocking:  sk = "block"
	elif is_hurt:      sk = "hurt"
	elif is_jumping:   sk = "jump"
	elif is_walking:   sk = "walk%d" % _walk_tick
	else:              sk = "idle%d" % _anim_tick

	if _png_texture != null:
		_draw_png(sk)
		return

	var frame: PackedStringArray
	var pal: Dictionary

	match char_name:
		"Goku":
			frame = PixelGoku.get_frame(sk)
			pal   = PixelGoku.PALETTE
		"Naruto":
			frame = PixelNaruto.get_frame(sk)
			pal   = PixelNaruto.PALETTE
		"Luffy":
			frame = PixelLuffy.get_frame(sk)
			pal   = PixelLuffy.PALETTE
		"Conan":
			frame = PixelConan.get_frame(sk)
			pal   = PixelConan.PALETTE
		"Doraemon":
			frame = PixelDoraemon.get_frame(sk)
			pal   = PixelDoraemon.PALETTE
		"Sakura":
			frame = PixelSakura.get_frame(sk)
			pal   = PixelSakura.PALETTE
		_:
			return

	_render_pixels(frame, pal)

func _draw_png(sk: String) -> void:
	var char_frames: Dictionary = PNG_FRAME_DATA.get(char_name, {})
	var frames: Array = char_frames.get(sk, char_frames.get("idle0", []))
	if frames.is_empty():
		return
	var region: Rect2 = frames[0]
	var dw := region.size.x * PNG_SCALE
	var dh := region.size.y * PNG_SCALE
	var dst := Rect2(-dw * 0.5, -dh, dw, dh)
	var mod := flash_color if _flash_timer > 0.0 else Color.WHITE
	draw_texture_rect_region(_png_texture, dst, region, mod)
	# Ground shadow
	for i in int(dw):
		var t := float(i) / dw
		var a := 0.35 * sin(t * PI)
		draw_rect(Rect2(-dw * 0.5 + i, 1, 1, 3), Color(0, 0, 0, a))

# Renders a PackedStringArray frame using the given palette.
# Row 0 = top, last row = bottom. Column 0 = left edge.
# Origin (0,0) = character feet, so sprite renders upward.
func _render_pixels(frame: PackedStringArray, pal: Dictionary) -> void:
	if frame.is_empty():
		return
	var h    := frame.size()
	var ox   := -(SPRITE_W * PX) / 2
	var oy   := -h * PX
	var flash_active := _flash_timer > 0.0

	for row in h:
		var line: String = frame[row]
		for col in min(line.length(), SPRITE_W):
			var key := line[col]
			if key == ".":
				continue
			var c: Color = flash_color if flash_active else pal.get(key, Color(1, 0, 1))
			draw_rect(Rect2(ox + col * PX, oy + row * PX, PX, PX), c)

	# Soft ground shadow
	var sw := SPRITE_W * PX
	var sx := -(sw / 2)
	for i in sw:
		var t := float(i) / sw
		var a := 0.35 * sin(t * PI)
		draw_rect(Rect2(sx + i, 1, 1, 3), Color(0, 0, 0, a))
