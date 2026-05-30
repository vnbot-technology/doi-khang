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
	"Sasuke":      "res://assets/sprites/sasuke_sheet.png",
	"Naruto":      "res://assets/sprites/naruto_sheet.png",
	"Choji":       "res://assets/sprites/choji_sheet.png",
	"Himawari":    "res://assets/sprites/himawari_sheet.png",
	"Hinata":      "res://assets/sprites/hinata_sheet.png",
	"Kakashi":     "res://assets/sprites/kakashi_sheet.png",
	"Kakuzu":      "res://assets/sprites/kakuzu_sheet.png",
	"Kiba":        "res://assets/sprites/kiba_sheet.png",
	"Kurenai":     "res://assets/sprites/kurenai_sheet.png",
	"Neji":        "res://assets/sprites/neji_sheet.png",
	"Orochimaru":  "res://assets/sprites/orochimaru_sheet.png",
	"Rock Lee":    "res://assets/sprites/rocklee_sheet.png",
	"Sasori":      "res://assets/sprites/sasori_sheet.png",
	"Sasuke TS":   "res://assets/sprites/sasuke_ts_sheet.png",
	"Shikadai":    "res://assets/sprites/shikadai_sheet.png",
	"Shikamaru":   "res://assets/sprites/shikamaru_sheet.png",
	"Shino":       "res://assets/sprites/shino_sheet.png",
	"Shino Adult": "res://assets/sprites/shino_adult_sheet.png",
	"Tenten":      "res://assets/sprites/tenten_sheet.png",
	"Tsunade":     "res://assets/sprites/tsunade_sheet.png",
	"Zaku":        "res://assets/sprites/zaku_sheet.png",
}

# Per-character frame regions (Rect2) keyed by animation state name.
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
	},
	"Naruto": {
		"idle0":  [Rect2( 14, 1032, 53, 60)],
		"idle1":  [Rect2(159, 1032, 47, 59)],
		"walk0":  [Rect2(  6,  581, 50, 58)],
		"walk1":  [Rect2(136,  581, 61, 56)],
		"jump":   [Rect2( 33,  723, 46, 58)],
		"attack": [Rect2( 68,  581, 58, 57)],
		"block":  [Rect2( 81, 1033, 52, 57)],
		"hurt":   [Rect2(213, 1114, 63, 33)],
		"dead":   [Rect2(284, 1132, 65, 21)],
	},
	"Choji": {
		"idle0":  [Rect2(51,50,49,64)],   "idle1":  [Rect2(101,51,49,62)],
		"walk0":  [Rect2(151,54,47,59)],  "walk1":  [Rect2(305,56,48,62)],
		"jump":   [Rect2(48,162,35,66)],  "attack": [Rect2(280,1988,131,109)],
		"block":  [Rect2(151,54,47,59)],  "hurt":   [Rect2(263,1800,53,55)],
		"dead":   [Rect2(522,2290,203,24)],
	},
	"Himawari": {
		"idle0":  [Rect2(23,83,33,56)],   "idle1":  [Rect2(67,83,33,56)],
		"walk0":  [Rect2(113,81,33,58)],  "walk1":  [Rect2(160,79,33,60)],
		"jump":   [Rect2(6,209,25,60)],   "attack": [Rect2(330,1643,100,104)],
		"block":  [Rect2(23,83,33,56)],   "hurt":   [Rect2(13,927,45,57)],
		"dead":   [Rect2(191,475,55,25)],
	},
	"Hinata": {
		"idle0":  [Rect2(51,23,33,54)],   "idle1":  [Rect2(98,27,33,55)],
		"walk0":  [Rect2(150,29,33,56)],  "walk1":  [Rect2(245,27,33,56)],
		"jump":   [Rect2(31,110,33,51)],  "attack": [Rect2(743,2506,131,118)],
		"block":  [Rect2(51,23,33,54)],   "hurt":   [Rect2(12,1624,36,41)],
		"dead":   [Rect2(229,1710,54,25)],
	},
	"Kakashi": {
		"idle0":  [Rect2(44,48,32,50)],   "idle1":  [Rect2(95,47,32,50)],
		"walk0":  [Rect2(153,46,32,50)],  "walk1":  [Rect2(261,42,32,50)],
		"jump":   [Rect2(37,127,32,54)],  "attack": [Rect2(409,220,72,95)],
		"block":  [Rect2(333,41,38,46)],  "hurt":   [Rect2(46,483,33,78)],
		"dead":   [Rect2(46,483,33,78)],
	},
	"Kakuzu": {
		"idle0":  [Rect2(33,235,33,73)],  "idle1":  [Rect2(95,235,35,73)],
		"walk0":  [Rect2(162,235,32,73)], "walk1":  [Rect2(227,234,30,74)],
		"jump":   [Rect2(25,392,34,73)],  "attack": [Rect2(664,5918,190,71)],
		"block":  [Rect2(33,235,33,73)],  "hurt":   [Rect2(55,2716,63,73)],
		"dead":   [Rect2(81,4847,218,25)],
	},
	"Kiba": {
		"idle0":  [Rect2(563,33,15,26)],  "idle1":  [Rect2(580,31,19,28)],
		"walk0":  [Rect2(643,31,19,28)],  "walk1":  [Rect2(696,40,18,28)],
		"jump":   [Rect2(10,337,42,55)],  "attack": [Rect2(441,6386,196,146)],
		"block":  [Rect2(563,33,15,26)],  "hurt":   [Rect2(50,2745,40,23)],
		"dead":   [Rect2(303,849,60,21)],
	},
	"Kurenai": {
		"idle0":  [Rect2(26,47,38,60)],   "idle1":  [Rect2(88,47,39,60)],
		"walk0":  [Rect2(156,48,38,59)],  "walk1":  [Rect2(807,40,80,44)],
		"jump":   [Rect2(24,159,21,61)],  "attack": [Rect2(625,2267,54,96)],
		"block":  [Rect2(221,49,38,58)],  "hurt":   [Rect2(122,1311,40,48)],
		"dead":   [Rect2(321,1138,60,21)],
	},
	"Neji": {
		"idle0":  [Rect2(5,18,32,42)],    "idle1":  [Rect2(57,19,35,41)],
		"walk0":  [Rect2(112,19,33,41)],  "walk1":  [Rect2(218,5,56,55)],
		"jump":   [Rect2(5,76,44,39)],    "attack": [Rect2(5,416,185,144)],
		"block":  [Rect2(550,24,33,36)],  "hurt":   [Rect2(10,363,29,40)],
		"dead":   [Rect2(10,363,29,40)],
	},
	"Orochimaru": {
		"idle0":  [Rect2(160,77,29,67)],  "idle1":  [Rect2(241,86,42,59)],
		"walk0":  [Rect2(314,86,47,59)],  "walk1":  [Rect2(508,77,85,60)],
		"jump":   [Rect2(149,221,53,64)], "attack": [Rect2(1764,6011,200,119)],
		"block":  [Rect2(241,86,42,59)],  "hurt":   [Rect2(103,2556,39,64)],
		"dead":   [Rect2(1261,3767,73,22)],
	},
	"Rock Lee": {
		"idle0":  [Rect2(4,24,39,42)],    "idle1":  [Rect2(63,24,32,42)],
		"walk0":  [Rect2(115,5,55,61)],   "walk1":  [Rect2(259,5,54,61)],
		"jump":   [Rect2(4,103,54,173)],  "attack": [Rect2(593,315,88,142)],
		"block":  [Rect2(437,29,35,37)],  "hurt":   [Rect2(0,544,39,40)],
		"dead":   [Rect2(69,1156,44,25)],
	},
	"Sasori": {
		"idle0":  [Rect2(9,18,78,68)],    "idle1":  [Rect2(97,13,78,71)],
		"walk0":  [Rect2(185,13,78,69)],  "walk1":  [Rect2(367,13,77,70)],
		"jump":   [Rect2(25,117,58,72)],  "attack": [Rect2(652,957,146,130)],
		"block":  [Rect2(567,16,15,61)],  "hurt":   [Rect2(16,747,78,47)],
		"dead":   [Rect2(772,1757,67,22)],
	},
	"Sasuke TS": {
		"idle0":  [Rect2(40,231,40,61)],  "idle1":  [Rect2(121,231,38,60)],
		"walk0":  [Rect2(210,235,37,59)], "walk1":  [Rect2(379,242,37,59)],
		"jump":   [Rect2(48,381,55,48)],  "attack": [Rect2(330,5228,190,135)],
		"block":  [Rect2(210,235,37,59)], "hurt":   [Rect2(100,4067,93,76)],
		"dead":   [Rect2(881,5944,178,26)],
	},
	"Shikadai": {
		"idle0":  [Rect2(21,167,31,57)],  "idle1":  [Rect2(59,167,31,57)],
		"walk0":  [Rect2(95,169,31,55)],  "walk1":  [Rect2(165,170,31,53)],
		"jump":   [Rect2(29,255,19,58)],  "attack": [Rect2(158,1376,173,63)],
		"block":  [Rect2(165,170,31,53)], "hurt":   [Rect2(28,804,34,45)],
		"dead":   [Rect2(27,1706,160,21)],
	},
	"Shikamaru": {
		"idle0":  [Rect2(46,116,27,63)],  "idle1":  [Rect2(117,125,26,62)],
		"walk0":  [Rect2(190,128,26,63)], "walk1":  [Rect2(341,127,26,64)],
		"jump":   [Rect2(62,264,21,63)],  "attack": [Rect2(446,4664,124,65)],
		"block":  [Rect2(117,125,26,62)], "hurt":   [Rect2(64,1994,25,55)],
		"dead":   [Rect2(389,1008,66,21)],
	},
	"Shino": {
		"idle0":  [Rect2(40,75,24,61)],   "idle1":  [Rect2(95,75,25,61)],
		"walk0":  [Rect2(146,76,25,61)],  "walk1":  [Rect2(274,77,25,61)],
		"jump":   [Rect2(44,170,38,49)],  "attack": [Rect2(313,3362,127,135)],
		"block":  [Rect2(40,75,24,61)],   "hurt":   [Rect2(8,2307,54,74)],
		"dead":   [Rect2(230,994,59,24)],
	},
	"Shino Adult": {
		"idle0":  [Rect2(40,70,24,69)],   "idle1":  [Rect2(95,71,25,68)],
		"walk0":  [Rect2(146,70,25,70)],  "walk1":  [Rect2(274,71,25,70)],
		"jump":   [Rect2(44,165,38,56)],  "attack": [Rect2(313,3362,127,135)],
		"block":  [Rect2(95,71,25,68)],   "hurt":   [Rect2(128,2316,51,67)],
		"dead":   [Rect2(319,996,64,20)],
	},
	"Tenten": {
		"idle0":  [Rect2(50,24,37,55)],   "idle1":  [Rect2(94,25,39,54)],
		"walk0":  [Rect2(141,27,40,51)],  "walk1":  [Rect2(232,27,40,51)],
		"jump":   [Rect2(61,111,37,43)],  "attack": [Rect2(547,6024,88,142)],
		"block":  [Rect2(187,28,40,50)],  "hurt":   [Rect2(27,2316,48,40)],
		"dead":   [Rect2(355,1835,56,30)],
	},
	"Tsunade": {
		"idle0":  [Rect2(10,10,30,63)],   "idle1":  [Rect2(51,12,32,61)],
		"walk0":  [Rect2(96,13,30,60)],   "walk1":  [Rect2(238,16,34,62)],
		"jump":   [Rect2(23,166,34,60)],  "attack": [Rect2(207,266,174,67)],
		"block":  [Rect2(96,13,30,60)],   "hurt":   [Rect2(129,642,31,60)],
		"dead":   [Rect2(107,485,218,25)],
	},
	"Zaku": {
		"idle0":  [Rect2(36,58,36,53)],   "idle1":  [Rect2(79,59,36,52)],
		"walk0":  [Rect2(124,59,36,52)],  "walk1":  [Rect2(171,59,37,52)],
		"jump":   [Rect2(37,153,40,49)],  "attack": [Rect2(27,1303,58,55)],
		"block":  [Rect2(79,59,36,52)],   "hurt":   [Rect2(20,916,44,51)],
		"dead":   [Rect2(254,1783,49,27)],
	},
}

# Per-character render scales (fallback: 2.0)
const PNG_SCALES: Dictionary = {
	"Sasuke": 2.0,   "Naruto":      1.5,
	"Choji":  1.41,  "Himawari":    1.61,
	"Hinata": 1.67,  "Kakashi":     1.8,
	"Kakuzu": 1.23,  "Kiba":        3.46,
	"Kurenai":1.5,   "Neji":        2.14,
	"Orochimaru":1.34,"Rock Lee":   2.14,
	"Sasori": 1.32,  "Sasuke TS":   1.48,
	"Shikadai":1.58, "Shikamaru":   1.43,
	"Shino":  1.48,  "Shino Adult": 1.3,
	"Tenten": 1.64,  "Tsunade":     1.43,
	"Zaku":   1.7,
}

const PNG_SCALE := 2.0   # kept for fallback; use PNG_SCALES.get(char_name, PNG_SCALE)

var _png_texture: Texture2D = null

func _ready() -> void:
	if char_name in PNG_SPRITE_PATHS:
		_png_texture = load(PNG_SPRITE_PATHS[char_name]) as Texture2D

var char_name: String = ""
var base_color: Color = Color.WHITE  # kept for API compatibility
var is_attacking: bool = false
var is_special: bool = false   # true when current attack is a skill/ultimate (not normal attack)
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

	# Retry PNG load in case _ready() ran before the import cache was ready.
	if _png_texture == null and char_name in PNG_SPRITE_PATHS:
		_png_texture = load(PNG_SPRITE_PATHS[char_name]) as Texture2D

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
			# Guaranteed fallback: draw a colored silhouette so the character
			# is always visible even when sprites fail to load.
			var ccolor: Color = Global.CHARACTER_COLORS.get(char_name, Color.WHITE)
			if _flash_timer > 0.0:
				ccolor = flash_color
			draw_rect(Rect2(-18.0, -78.0, 36.0, 78.0), ccolor)
			draw_rect(Rect2(-12.0, -96.0, 24.0, 20.0), ccolor)
			_draw_shadow(36.0)
			return

	_render_pixels(frame, pal)

func _draw_png(sk: String) -> void:
	var char_frames: Dictionary = PNG_FRAME_DATA.get(char_name, {})
	var frames: Array = char_frames.get(sk, char_frames.get("idle0", []))
	if frames.is_empty():
		return
	var region: Rect2 = frames[0]
	var scale: float = PNG_SCALES.get(char_name, PNG_SCALE)
	var dw := region.size.x * scale
	var dh := region.size.y * scale

	# Cap rendered height per frame type so large sprite-sheet sequences (attack
	# moves, jump arcs) don't explode to hundreds of screen pixels.
	var cap: float
	match sk:
		"attack": cap = 115.0
		"jump":   cap = 108.0
		"hurt":   cap = 100.0
		_:        cap = 98.0
	if dh > cap:
		var r := cap / dh
		dw *= r
		dh = cap

	var dst := Rect2(-dw * 0.5, -dh, dw, dh)

	# Normal attack: plain white (brief flash already applied by _flash_color).
	# Special/ultimate: persistent character-color tint so they look distinct.
	var mod := Color.WHITE
	if _flash_timer > 0.0:
		mod = flash_color
	elif is_special and is_attacking:
		var ccolor: Color = Global.CHARACTER_COLORS.get(char_name, Color.WHITE)
		mod = Color.WHITE.lerp(ccolor.lightened(0.35), 0.45)

	draw_texture_rect_region(_png_texture, dst, region, mod)
	_draw_shadow(dw)

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
			var base_c: Color = pal.get(key, Color(1, 0, 1))
			var c: Color
			if flash_active:
				# Blend 70% flash with 30% base so silhouette detail survives.
				c = base_c.lerp(flash_color, 0.7)
			else:
				c = base_c
			draw_rect(Rect2(ox + col * PX, oy + row * PX, PX, PX), c)

	_draw_shadow(SPRITE_W * PX)

# Soft elliptical ground shadow centered on the sprite's local origin (feet).
# Uses a sin-based alpha fall-off so edges fade rather than clip.
func _draw_shadow(width: float, offset_x: float = 0.0) -> void:
	var w := int(width)
	if w <= 0:
		return
	for i in w:
		var t := float(i) / width
		var a := 0.35 * sin(t * PI)
		draw_rect(Rect2(offset_x - width * 0.5 + i, 1, 1, 3), Color(0, 0, 0, a))
