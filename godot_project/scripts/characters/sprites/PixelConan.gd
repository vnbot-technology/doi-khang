class_name PixelConan

const PALETTE: Dictionary = {
	"K": Color(0.08, 0.08, 0.08),
	"W": Color(0.97, 0.97, 0.97),
	"S": Color(0.94, 0.80, 0.64),
	"s": Color(0.78, 0.64, 0.50),
	"A": Color(0.20, 0.38, 0.82),
	"a": Color(0.14, 0.26, 0.60),
	"B": Color(0.15, 0.15, 0.18),
	"b": Color(0.08, 0.08, 0.10),
	"H": Color(0.10, 0.10, 0.12),
	"h": Color(0.04, 0.04, 0.06),
	"E": Color(0.97, 0.97, 0.97),
	"P": Color(0.15, 0.20, 0.65),
	"R": Color(0.90, 0.12, 0.12),
	"G": Color(0.72, 0.76, 0.88),
	"Y": Color(1.00, 0.90, 0.10),
	"N": Color(0.70, 0.55, 0.40),
}

static func get_frame(state: String) -> PackedStringArray:
	match state:
		"idle0":  return IDLE0
		"idle1":  return IDLE1
		"attack": return ATTACK
		"block":  return BLOCK
		"dead":   return DEAD
	return IDLE0

# Conan = child proportions: BIG head, short body, short legs.
# Each row MUST be exactly 20 characters.
# Layout:
#  rows 0-5  : black side-part hair
#  rows 6-8  : forehead / upper face
#  rows 9-12 : round glasses with eyes inside
#  rows 13-15: lower face (nose, mouth, chin)
#  row 16    : neck
#  row 17    : red bow tie
#  rows 18-24: blue jacket / torso
#  rows 25-27: dark shorts
#  rows 28-31: short legs (white socks + black shoes)
static var IDLE0 := PackedStringArray([
	"...KKKKKKKKKKKKK....",
	"..KHHHHHHHHHHHHHK...",
	".KHHHhhHHHHHHHHHHK..",
	".KHHhhSSSSSSSSHHHK..",
	".KHSSSSSSSSSSSSHHK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	"..KSGGGSSSSSGGGSK...",
	"..KGEEEGSSSGEEEGK...",
	"..KGEPEGSSSGEPEGK...",
	"..KGGGGSSSSSGGGGK...",
	"..KSSSSSSNNSSSSSK...",
	"..KSSSSSSKKSSSSSK...",
	"..KSSSSSKWWKSSSSK...",
	"...KKSSSSSSSSSKK....",
	".....KRRRRRRRK......",
	"..AAAAAAAAAAAAAAA...",
	"..AAaAAAAWWAAAAaA...",
	"..AAaAAAAAAAAAAaA...",
	".SAAaAAAAAAAAAAaAS..",
	".SAAaAAAAAAAAAAaAS..",
	"..AAAaAAAAAAAAaAA...",
	"..AAAAAAaaaaAAAAA...",
	"...BBBBBBBBBBBBB....",
	"...BBBbBBBBBBbBB....",
	"...BBBBB..BBBBBB....",
	"....WWWW..WWWWW.....",
	"....WWWW..WWWWW.....",
	"...KKKKK..KKKKKK....",
	"..KKKKKK..KKKKKKK...",
])

static var IDLE1 := PackedStringArray([
	"....................",
	"...KKKKKKKKKKKKK....",
	"..KHHHHHHHHHHHHHK...",
	".KHHHhhHHHHHHHHHHK..",
	".KHHhhSSSSSSSSHHHK..",
	".KHSSSSSSSSSSSSHHK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	"..KSGGGSSSSSGGGSK...",
	"..KGEEEGSSSGEEEGK...",
	"..KGEPEGSSSGEPEGK...",
	"..KGGGGSSSSSGGGGK...",
	"..KSSSSSSNNSSSSSK...",
	"..KSSSSSSKKSSSSSK...",
	"..KSSSSSKWWKSSSSK...",
	".....KRRRRRRRK......",
	"..AAAAAAAAAAAAAAA...",
	"..AAaAAAAWWAAAAaA...",
	"..AAaAAAAAAAAAAaA...",
	".SAAaAAAAAAAAAAaAS..",
	".SAAaAAAAAAAAAAaAS..",
	"..AAAaAAAAAAAAaAA...",
	"..AAAAAAaaaaAAAAA...",
	"...BBBBBBBBBBBBB....",
	"...BBBbBBBBBBbBB....",
	"...BBBBB..BBBBBB....",
	"....WWWW..WWWWW.....",
	"....WWWW..WWWWW.....",
	"...KKKKK..KKKKKK....",
	"..KKKKKK..KKKKKKK...",
])

# Attack: soccer ball kick! Right arm/leg forward, ball flying off to the right.
static var ATTACK := PackedStringArray([
	"...KKKKKKKKKKKKK....",
	"..KHHHHHHHHHHHHHK...",
	".KHHHhhHHHHHHHHHHK..",
	".KHHhhSSSSSSSSHHHK..",
	".KHSSSSSSSSSSSSHHK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	"..KSGGGSSSSSGGGSK...",
	"..KGEEEGSSSGEEEGK...",
	"..KGEPEGSSSGEPEGK...",
	"..KGGGGSSSSSGGGGK...",
	"..KSSSSSSNNSSSSSK...",
	"..KSSSSSSKKSSSSSK...",
	"..KSSSSKWWWKSSSSK...",
	"...KKSSSSSSSSSKK....",
	".....KRRRRRRRK......",
	"..AAAAAAAAAAAAAAA...",
	"..AAaAAAAWWAAAAaA...",
	"..AAaAAAAAAAAAAaA...",
	".SAAaAAAAAAAAAAaAS..",
	".SAAaAAAAAAAAAAaAS..",
	"..AAAaAAAAAAAAaAA...",
	"..AAAAAAaaaaAAAAA...",
	"...BBBBBBBBBBKWWK...",
	"...BBBbBBBBBKWKWKK..",
	"...BBBSSSBBKWKWKWK..",
	"....WWWSSSWWKWKWKK..",
	"....WWWWSSWWKKWWK...",
	"...KKKKKSKKKKKKK....",
	"..KKKKKKKKKKKKK.....",
])

# Block: arms raised in front, slight crouch (whole body shifted down 1 row).
static var BLOCK := PackedStringArray([
	"....................",
	"...KKKKKKKKKKKKK....",
	"..KHHHHHHHHHHHHHK...",
	".KHHHhhHHHHHHHHHHK..",
	".KHHhhSSSSSSSSHHHK..",
	".KHSSSSSSSSSSSSHHK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	".KSSSSSSSSSSSSSSSK..",
	"..KSGGGSSSSSGGGSK...",
	"..KGEEEGSSSGEEEGK...",
	"..KGEPEGSSSGEPEGK...",
	"..KGGGGSSSSSGGGGK...",
	"..KSSSSSSNNSSSSSK...",
	"..KSSSSSSKKSSSSSK...",
	"..KSSSSSKWWKSSSSK...",
	".....KRRRRRRRK......",
	"..SSSSAAAAAAAASSSS..",
	"..SSSSAAaaaaAASSSS..",
	"..SSSSAAAAAAAASSSS..",
	"..AAAaAAAAAAAAaAA...",
	"..AAAaAAAAAAAAaAA...",
	"..AAAAAAaaaaAAAAA...",
	"...BBBBBBBBBBBBB....",
	"...BBBbBBBBBBbBB....",
	"...BBBBB..BBBBBB....",
	"....WWWW..WWWWW.....",
	"....WWWW..WWWWW.....",
	"...KKKKK..KKKKKK....",
	"..KKKKKK..KKKKKKK...",
	"..KKKKKK..KKKKKKK...",
])

# Dead: lying flat on the ground, glasses askew, X eyes.
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
	"..KKKK..............",
	".KHHHHK.............",
	".KSSSSKAAAAAAA......",
	".KKPKPKAAaaaaAAAA...",
	".KSKSKSAAAAAAAAAAK..",
	".KSRRSSKAAAAAAAAKK..",
	"..KssssK.BBBBBKK....",
	"...KKKK....WWKK.....",
])
