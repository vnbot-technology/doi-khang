class_name PixelSakura

const PALETTE: Dictionary = {
	"K": Color(0.08, 0.08, 0.08),
	"W": Color(0.96, 0.96, 0.96),
	"S": Color(0.97, 0.86, 0.74),
	"s": Color(0.82, 0.70, 0.58),
	"A": Color(0.88, 0.12, 0.22),
	"a": Color(0.65, 0.06, 0.14),
	"B": Color(0.12, 0.12, 0.14),
	"H": Color(0.96, 0.48, 0.66),
	"h": Color(0.82, 0.32, 0.52),
	"E": Color(0.97, 0.97, 0.97),
	"P": Color(0.22, 0.68, 0.28),
	"R": Color(0.90, 0.12, 0.20),
	"Y": Color(1.00, 0.90, 0.10),
	"V": Color(0.62, 0.22, 0.72),
	"N": Color(0.82, 0.65, 0.50),
	"G": Color(0.76, 0.80, 0.84),
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
	".....HHHHHHHHHH.....",
	"....HHHHHHHHHHHH....",
	"...HHHHHHHHHHHHHH...",
	"..RRRRRRRRRRRRRRRR..",
	"..HHHSSSSSSSSSSHHH..",
	"..HHSSSSSVVVSSSSSHH.",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSEEPSSSPEESSHh.",
	"..hHSSEPESSEPESSSHh.",
	"..hHSSSSSSSSSSSSSHh.",
	"..hHSSSSSNNSSSSSSHh.",
	"..hHSSSSSSsSSSSSSHh.",
	"..hHSSSSSsssSSSSSHh.",
	"...hHSSSSSSSSSSSHh..",
	"....hHSSSSSSSSSHh...",
	"....AAAWWWWWWAAAA...",
	"...AAAAAAAAAAAAAA...",
	"...AAAAAAAAAAAAAA...",
	"..SAAAAAAAAAAAAAAS..",
	"..SAAAAAAAAAAAAAAS..",
	"...AAAAAAAAAAAAAA...",
	"...AAaAAAAAAAAAaA...",
	"...AAAAAAAAAAAAAA...",
	"...AAAAAAAAAAAAAA...",
	"....BBBBBBBBBBBB....",
	"....BBBBBBBBBBBB....",
	"....SSSS....SSSS....",
	"....KKKK....KKKK....",
	"....KKKK....KKKK....",
	"...KKKKK....KKKKK...",
	"...KKKKK....KKKKK...",
])

static var IDLE1 := PackedStringArray([
	".....HHHHHHHHHH.....",
	"....HHHHHHHHHHHH....",
	"...HHHHHHHHHHHHHH...",
	"..RRRRRRRRRRRRRRRR..",
	"..HHHSSSSSSSSSSHHH..",
	"..HHSSSSSVVVSSSSSHH.",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSEEPSSSPEESSHh.",
	"..hHSSEPESSEPESSSHh.",
	"..hHSSSSSSSSSSSSSHh.",
	"..hHSSSSSNNSSSSSSHh.",
	"..hHSSSSSSsSSSSSSHh.",
	"..hHSSSSSsssSSSSSHh.",
	"...hHSSSSSSSSSSSHh..",
	"....hHSSSSSSSSSHh...",
	"....................",
	"....AAAWWWWWWAAAA...",
	"...AAAAAAAAAAAAAA...",
	"..SAAAAAAAAAAAAAAS..",
	"..SAAAAAAAAAAAAAAS..",
	"...AAAAAAAAAAAAAA...",
	"...AAaAAAAAAAAAaA...",
	"...AAAAAAAAAAAAAA...",
	"...AAAAAAAAAAAAAA...",
	"....BBBBBBBBBBBB....",
	"....BBBBBBBBBBBB....",
	"....SSSS....SSSS....",
	"....KKKK....KKKK....",
	"....KKKK....KKKK....",
	"...KKKKK....KKKKK...",
	"...KKKKK....KKKKK...",
])

static var ATTACK := PackedStringArray([
	".....HHHHHHHHHH.....",
	"....HHHHHHHHHHHH....",
	"...HHHHHHHHHHHHHH...",
	"..RRRRRRRRRRRRRRRR..",
	"..HHHSSSSSSSSSSHHH..",
	"..HHSSSSSVVVSSSSSHH.",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSEPESSSEPESSHh.",
	"..hHSSPEESSSEPSSSHh.",
	"..hHSSSSSSSSSSSSSHh.",
	"..hHSSSSSNNSSSSSSHh.",
	"..hHSSSSSSsSSSSSSHh.",
	"..hHSSSSsssSSSSSSHh.",
	"...hHSSSSSSSSSSSHh..",
	"....hHSSSSSSSSSHh...",
	"....AAAWWWWWWAAYSSY.",
	"...AAAAAAAAAAAYSSSYY",
	"...AAAAAAAAAAAYSSSYY",
	"..SAAAAAAAAAAAAYYYY.",
	"..SAAAAAAAAAAAAAAS..",
	"...AAAAAAAAAAAAAA...",
	"...AAaAAAAAAAAAaA...",
	"...AAAAAAAAAAAAAA...",
	"...AAAAAAAAAAAAAA...",
	"....BBBBBBBBBBBB....",
	"....BBBBBBBBBBBB....",
	"....SSSS....SSSS....",
	"....KKKK....KKKK....",
	"....KKKK....KKKK....",
	"...KKKKK....KKKKK...",
	"...KKKKK....KKKKK...",
])

static var BLOCK := PackedStringArray([
	"....................",
	".....HHHHHHHHHH.....",
	"....HHHHHHHHHHHH....",
	"...HHHHHHHHHHHHHH...",
	"..RRRRRRRRRRRRRRRR..",
	"..HHHSSSSSSSSSSHHH..",
	"..HHSSSSSVVVSSSSSHH.",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSSSSSSSSSSSHh..",
	"..hHSSEEPSSSPEESSHh.",
	"..hHSSEPESSEPESSSHh.",
	"..hHSSSSSSSSSSSSSHh.",
	"..hHSSSSSNNSSSSSSHh.",
	"..hHSSSSSSsSSSSSSHh.",
	"..hHSSSSSsssSSSSSHh.",
	"...hHSSSSSSSSSSSHh..",
	"....AAAWWWWWWAAAA...",
	"..SSSAAAAAAAAAASSS..",
	"..SSSAAAAAAAAAASSS..",
	"..SSSAAAAAAAAAASSS..",
	"...AAAAAAAAAAAAAA...",
	"...AAaAAAAAAAAAaA...",
	"...AAAAAAAAAAAAAA...",
	"...AAAAAAAAAAAAAA...",
	"...AAAAAAAAAAAAAA...",
	"....BBBBBBBBBBBB....",
	"....BBBBBBBBBBBB....",
	"....SSSS....SSSS....",
	"....KKKK....KKKK....",
	"....KKKK....KKKK....",
	"...KKKKK....KKKKK...",
	"...KKKKK....KKKKK...",
])

static func _make_walk0() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Sakura: S=skin legs, K=dark shoes (rows 27-31 in IDLE0)
	f[27] = ".....SSSS.....SSSS.."
	f[28] = ".....KKKK.....KKKK.."
	f[29] = ".....KKKK.....KKKK.."
	f[30] = "....KKKKK.....KKKKK."
	f[31] = "....KKKKK.....KKKKK."
	return f

static func _make_walk1() -> PackedStringArray:
	var f := IDLE0.duplicate()
	f[27] = "...SSSS.....SSSS...."
	f[28] = "...KKKK.....KKKK...."
	f[29] = "...KKKK.....KKKK...."
	f[30] = "..KKKKK.....KKKKK..."
	f[31] = "..KKKKK.....KKKKK..."
	return f

static func _make_jump() -> PackedStringArray:
	var f := IDLE0.duplicate()
	f[27] = ".....SSSS..SSSS....."
	f[28] = ".....KKKK..KKKK....."
	f[29] = ".....KKKK..KKKK....."
	f[30] = "....KKKKK..KKKKK...."
	f[31] = "....KKKKK..KKKKK...."
	return f

static func _make_hurt() -> PackedStringArray:
	var f := IDLE0.duplicate()
	for i in range(16, 28):
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
	"HHH.................",
	"HHHHH...............",
	"HHSSSSH.............",
	"HSKSKSH.AAAAAAAAA...",
	"HSSKSSHAAAAAAAAAAA..",
	".HSSSH.AAAAAAAABBKK.",
])
