class_name PixelGoku

const PALETTE: Dictionary = {
	"K": Color(0.08, 0.08, 0.08),
	"W": Color(0.95, 0.95, 0.92),
	"S": Color(0.93, 0.78, 0.60),
	"s": Color(0.76, 0.62, 0.46),
	"A": Color(0.95, 0.50, 0.10),
	"a": Color(0.68, 0.33, 0.05),
	"B": Color(0.22, 0.40, 0.84),
	"E": Color(0.97, 0.97, 0.97),
	"P": Color(0.18, 0.18, 0.55),
	"Y": Color(1.00, 0.92, 0.18),
	"N": Color(0.70, 0.55, 0.40),
}

static func get_frame(state: String) -> PackedStringArray:
	match state:
		"idle0":  return IDLE0
		"idle1":  return IDLE1
		"attack": return ATTACK
		"block":  return BLOCK
		"dead":   return DEAD
		"walk0":  return WALK0
		"walk1":  return WALK1
		"jump":   return JUMP
		"hurt":   return HURT
	return IDLE0

static var IDLE0 := PackedStringArray([
	"...K.KKK..KKK.K.....",
	"..KK.KKK.KKK.KK.....",
	".KK.KKKKKKKKK.KK....",
	".KKKKKKKKKKKKKKKK...",
	"..KKKKKKKKKKKKKKK...",
	"...KKSSSSSSSSKKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSEEPSSPEESK....",
	"...KSSEEPSSPEESK....",
	"...KSSSSSSSSSSSK....",
	"...KSSSSNNSSSSSK....",
	"...KSSSSSSSSSSSK....",
	"...KSSSsssssSSSK....",
	"...KBBWWWWWWWWBB....",
	"...AAAAAAAAAAAAAA...",
	"...AAaAAAAAAAAaAA...",
	"..SAAAAAAAAAAAAS....",
	"..SAAAAAAAAAAAAS....",
	"...AAAAAAAAAAAAA....",
	"...AAaAAAAAAAAaA....",
	"...AAAAAAAAAAAAA....",
	"...AAAAAAAAAAAAA....",
	"...BBBBBBBBBBBBBB...",
	"...BBBBBBBBBBBBBB...",
	"...AAAAAAaaAAAAAA...",
	"...AAaAAAaaAAAAaA...",
	"...KKKK......KKKK...",
	"...KKKK......KKKK...",
	"..KKKKK......KKKKK..",
	"..KKKKK......KKKKK..",
])

static var IDLE1 := PackedStringArray([
	"...K.KKK..KKK.K.....",
	"..KK.KKK.KKK.KK.....",
	".KK.KKKKKKKKK.KK....",
	".KKKKKKKKKKKKKKKK...",
	"..KKKKKKKKKKKKKKK...",
	"...KKSSSSSSSSKKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSEEPSSPEESK....",
	"...KSSEEPSSPEESK....",
	"...KSSSSSSSSSSSK....",
	"...KSSSSNNSSSSSK....",
	"...KSSSSSSSSSSSK....",
	"...KSSSsssssSSSK....",
	"....................",
	"...KBBWWWWWWWWBB....",
	"...AAAAAAAAAAAAAA...",
	"...AAaAAAAAAAAaAA...",
	"..SAAAAAAAAAAAAS....",
	"..SAAAAAAAAAAAAS....",
	"...AAAAAAAAAAAAA....",
	"...AAaAAAAAAAAaA....",
	"...AAAAAAAAAAAAA....",
	"...BBBBBBBBBBBBBB...",
	"...BBBBBBBBBBBBBB...",
	"...AAAAAAaaAAAAAA...",
	"...AAaAAAaaAAAAaA...",
	"...KKKK......KKKK...",
	"...KKKK......KKKK...",
	"..KKKKK......KKKKK..",
	"..KKKKK......KKKKK..",
])

static var ATTACK := PackedStringArray([
	"...K.KKK..KKK.K.....",
	"..KK.KKK.KKK.KK.....",
	".KK.KKKKKKKKK.KK....",
	".KKKKKKKKKKKKKKKK...",
	"..KKKKKKKKKKKKKKK...",
	"...KKSSSSSSSSKKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSSSSSSSSSKK....",
	"....KSSSSSSSSSKK....",
	"....KSSPEESSPEESK...",
	"....KSSPEESSPEESK...",
	"....KSSSSSSSSSSSK...",
	"....KSSSSNNSSSSSK...",
	"....KSSSSSSSSSSSK...",
	"....KSSSsssssSSSK...",
	"....KBBWWWWWWWWBB...",
	"....AAAAAAAAAAAAAA..",
	"....AAaAAAAAAAASSSY.",
	"...SAAAAAAAAAAASYYY.",
	"...SAAAAAAAAAAASSSY.",
	"....AAAAAAAAAAAAA...",
	"....AAaAAAAAAAAaA...",
	"....AAAAAAAAAAAAA...",
	"....AAAAAAAAAAAAA...",
	"....BBBBBBBBBBBBBB..",
	"....BBBBBBBBBBBBBB..",
	"....AAAAAAaaAAAAAA..",
	"....AAaAAAaaAAAAaA..",
	"....KKKK......KKKK..",
	"....KKKK......KKKK..",
	"...KKKKK......KKKKK.",
	"...KKKKK......KKKKK.",
])

static var BLOCK := PackedStringArray([
	"....................",
	"...K.KKK..KKK.K.....",
	"..KK.KKK.KKK.KK.....",
	".KK.KKKKKKKKK.KK....",
	".KKKKKKKKKKKKKKKK...",
	"..KKKKKKKKKKKKKKK...",
	"...KKSSSSSSSSKKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSSSSSSSSSKK....",
	"...KSSEEPSSPEESK....",
	"...KSSEEPSSPEESK....",
	"...KSSSSSSSSSSSK....",
	"...KSSSSNNSSSSSK....",
	"...KSSSSSSSSSSSK....",
	"...KSSSsssssSSSK....",
	"...KBBWWWWWWWWBB....",
	"...SSSAAAAAAAASSS...",
	"...SSSAAAAAAAASSS...",
	"...SSSAAAAAAAASSS...",
	"...AAAAAAAAAAAAA....",
	"...AAaAAAAAAAAaA....",
	"...AAAAAAAAAAAAA....",
	"...AAAAAAAAAAAAA....",
	"...BBBBBBBBBBBBBB...",
	"...BBBBBBBBBBBBBB...",
	"...AAAAAAaaAAAAAA...",
	"...AAaAAAaaAAAAaA...",
	"...KKKK......KKKK...",
	"...KKKK......KKKK...",
	"..KKKKK......KKKKK..",
	"..KKKKK......KKKKK..",
])

static func _make_walk0() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Left leg forward, right leg back
	f[28] = "....KKKK.....KKKK..."
	f[29] = "....KKKK.....KKKK..."
	f[30] = "...KKKKK.....KKKKK.."
	f[31] = "...KKKKK.....KKKKK.."
	return f

static func _make_walk1() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Right leg forward, left leg back
	f[28] = "..KKKK.....KKKK....."
	f[29] = "..KKKK.....KKKK....."
	f[30] = ".KKKKK.....KKKKK...."
	f[31] = ".KKKKK.....KKKKK...."
	return f

static func _make_jump() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Both legs pulled up
	f[28] = ".....KKKK..KKKK....."
	f[29] = ".....KKKK..KKKK....."
	f[30] = "....KKKKK..KKKKK...."
	f[31] = "....KKKKK..KKKKK...."
	return f

static func _make_hurt() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Body leans back (shift body rows right by 2)
	for i in range(15, 28):
		if f[i].length() >= 20:
			f[i] = ".." + f[i].substr(0, 18)
	return f

static var WALK0 := _make_walk0()
static var WALK1 := _make_walk1()
static var JUMP  := _make_jump()
static var HURT  := _make_hurt()

static var DEAD := PackedStringArray([
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"..KKKK..............",
	".KSSSSK.............",
	".KSKPKSAAAAAAAAA....",
	".KSPKPSAAAAAAAAAA...",
	"..KSSK.AAAAAAAAAKK..",
])
