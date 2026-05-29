class_name PixelDoraemon

const PALETTE: Dictionary = {
	"K": Color(0.06, 0.06, 0.08),
	"W": Color(0.96, 0.96, 0.96),
	"A": Color(0.08, 0.68, 0.92),
	"a": Color(0.05, 0.50, 0.72),
	"R": Color(0.92, 0.12, 0.12),
	"r": Color(0.70, 0.08, 0.08),
	"Y": Color(1.00, 0.88, 0.12),
	"y": Color(0.82, 0.66, 0.06),
	"E": Color(0.04, 0.04, 0.06),
	"G": Color(0.82, 0.84, 0.88),
	"N": Color(0.92, 0.12, 0.12),
	"C": Color(0.88, 0.88, 0.90),
	"S": Color(0.96, 0.96, 0.96),
	"s": Color(0.82, 0.82, 0.82),
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
	"......AAAAAAAA......",
	"....AAAAAAAAAAAA....",
	"...AAAAAAAAAAAAAA...",
	"..AAAAAAAAAAAAAAAA..",
	"..AAAAAAAAAAAAAAAA..",
	".AAAAAWWWWWWWWAAAAA.",
	".AAAWWWWWWWWWWWWAAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWKEKWWWWKEKWWAA.",
	"CCAWWKEGWWWWKEGWWACC",
	"CCAWWKEKWWWWKEKWWACC",
	"CCAWWWWWWWWWWWWWWACC",
	".AAWWWWWRRWRRWWWWAA.",
	".AAWWWWWWRRWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	"..AAAAWWWWWWWWAAAA..",
	"...AAAAAAAAAAAAAA...",
	"....AAAAAAAAAAAA....",
	"..RRRRRRRRRRRRRRRR..",
	"..rRRRRRRRRRRRRRRr..",
	"........YYYY........",
	"........yYYy........",
	"...AAAAWWWWWWAAAA...",
	"..AAAWWWWWWWWWWAAA..",
	"..AAWWWWWWWWWWWWAA..",
	"..AAAWWWWWWWWWWAAA..",
	"...AAAA....AAAA.....",
	"..AAAAA....AAAAA....",
	"..AAAAA....AAAAA....",
	".AAAAAA....AAAAAA...",
	".AAAAAA....AAAAAA...",
])

static var IDLE1 := PackedStringArray([
	"......AAAAAAAA......",
	"....AAAAAAAAAAAA....",
	"...AAAAAAAAAAAAAA...",
	"..AAAAAAAAAAAAAAAA..",
	"..AAAAAAAAAAAAAAAA..",
	".AAAAAWWWWWWWWAAAAA.",
	".AAAWWWWWWWWWWWWAAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWKEKWWWWKEKWWAA.",
	"CCAWWKEGWWWWKEGWWACC",
	"CCAWWKEKWWWWKEKWWACC",
	"CCAWWWWWWWWWWWWWWACC",
	".AAWWWWWRRWRRWWWWAA.",
	".AAWWWWWWRRWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	"..AAAAWWWWWWWWAAAA..",
	"...AAAAAAAAAAAAAA...",
	"....AAAAAAAAAAAA....",
	"...RRRRRRRRRRRRRR...",
	"...rRRRRRRRRRRRRr...",
	"........YYYY........",
	"........yYYy........",
	"...AAAAWWWWWWAAAA...",
	"..AAAWWWWWWWWWWAAA..",
	"..AAWWWWWWWWWWWWAA..",
	"..AAAWWWWWWWWWWAAA..",
	"...AAAAA..AAAAA.....",
	"..AAAAAA..AAAAAA....",
	"..AAAAAA..AAAAAA....",
	".AAAAAAA..AAAAAAA...",
	".AAAAAAA..AAAAAAA...",
])

static var ATTACK := PackedStringArray([
	"......AAAAAAAA......",
	"....AAAAAAAAAAAA....",
	"...AAAAAAAAAAAAAA...",
	"..AAAAAAAAAAAAAAAA..",
	"..AAAAAAAAAAAAAAAA..",
	".AAAAAWWWWWWWWAAAAA.",
	".AAAWWWWWWWWWWWWAAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWKEKWWWWKEKWWAA.",
	"CCAWWKEGWWWWKEGWWACC",
	"CCAWWKEKWWWWKEKWWACC",
	"CCAWWWWWWWWWWWWWWACC",
	".AAWWWWWRRWRRWWWWAA.",
	".AAWWWWWWRRWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	"..AAAAWWWWWWWWAAAA..",
	"...AAAAAAAAAAAAAA...",
	"....AAAAAAAAAAAA....",
	"..RRRRRRRRRRRRRRRR..",
	"..rRRRRRRRRRRRRRRr..",
	"........YYYY..YYY...",
	"........yYYy.YYYY...",
	"...AAAAWWWWWWAAAYYY.",
	"..AAAWWWWWWWWWWAYYYY",
	"..AAWWWWWWWWWWWWAYY.",
	"..AAAWWWWWWWWWWAAA..",
	"...AAAA....AAAA.....",
	"..AAAAA....AAAAA....",
	"..AAAAA....AAAAA....",
	".AAAAAA....AAAAAA...",
	".AAAAAA....AAAAAA...",
])

static var BLOCK := PackedStringArray([
	"....................",
	"......AAAAAAAA......",
	"....AAAAAAAAAAAA....",
	"...AAAAAAAAAAAAAA...",
	"..AAAAAAAAAAAAAAAA..",
	".AAAAAWWWWWWWWAAAAA.",
	".AAAWWWWWWWWWWWWAAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	".AAWWKEKWWWWKEKWWAA.",
	"CCAWWKEGWWWWKEGWWACC",
	"CCAWWKEKWWWWKEKWWACC",
	"CCAWWWWWWWWWWWWWWACC",
	".AAWWWWWRRWRRWWWWAA.",
	".AAWWWWWWRRWWWWWWAA.",
	".AAWWWWWWWWWWWWWWAA.",
	"AAAAAAWWWWWWWWAAAAAA",
	"AAAAAAAAAAAAAAAAAAAA",
	"AAAAAAAAAAAAAAAAAAAA",
	"..RRRRRRRRRRRRRRRR..",
	"..rRRRRRRRRRRRRRRr..",
	"........YYYY........",
	"........yYYy........",
	"...AAAAWWWWWWAAAA...",
	"..AAAWWWWWWWWWWAAA..",
	"..AAWWWWWWWWWWWWAA..",
	"..AAAWWWWWWWWWWAAA..",
	"...AAAA....AAAA.....",
	"...AAAAA..AAAAA.....",
	"...AAAAA..AAAAA.....",
	"..AAAAAA..AAAAAA....",
	"..AAAAAA..AAAAAA....",
])

static func _make_walk0() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Doraemon: A=blue legs, waddle left foot forward
	f[27] = "....AAAA.....AAAA..."
	f[28] = "...AAAAA.....AAAAA.."
	f[29] = "...AAAAA.....AAAAA.."
	f[30] = "..AAAAAA.....AAAAAA."
	f[31] = "..AAAAAA.....AAAAAA."
	return f

static func _make_walk1() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Waddle right foot forward
	f[27] = "..AAAA.....AAAA....."
	f[28] = ".AAAAA.....AAAAA...."
	f[29] = ".AAAAA.....AAAAA...."
	f[30] = "AAAAAA.....AAAAAA..."
	f[31] = "AAAAAA.....AAAAAA..."
	return f

static func _make_jump() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Both legs tucked up
	f[27] = ".....AAAA..AAAA....."
	f[28] = "....AAAAA..AAAAA...."
	f[29] = "....AAAAA..AAAAA...."
	f[30] = "...AAAAAA..AAAAAA..."
	f[31] = "...AAAAAA..AAAAAA..."
	return f

static func _make_hurt() -> PackedStringArray:
	var f := IDLE0.duplicate()
	# Round body tilts back
	for i in range(18, 27):
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
	".....AAAA...........",
	"....AAAAAAA.........",
	"...AAWWWWWAAA.......",
	"..AAWKEKWWWKEKAA....",
	"..AWWWWWWWWWWWWAA...",
	"..AWWWRRWRRWWWWA....",
	".AAAAAAAAAAAAAAAA...",
	".AAAARRRRRRRRRAAA...",
	"AAAAAAYYAAAAAAAAAA..",
	"..AAA.....AAAAAA....",
	"..AAA.....AAAAAA....",
])
