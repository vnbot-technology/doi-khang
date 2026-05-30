extends Object
class_name StageLayout

# Platform and floor definitions per stage.
# All positions are in 1280x720 world space (background fills viewport non-uniformly).
# Each platform entry: { y, x1, x2 }  — y is top surface of platform.

const DATA: Dictionary = {
	"naruto.png": {
		"floor_y":   487,
		"spawn_y":   300,
		"platforms": [
			# The wide stone platform is the main floor — no floating platforms above it.
		],
		"tile_color": Color(0.45, 0.32, 0.18),
	},
	"dragonball.png": {
		"floor_y":   700,
		"spawn_y":   450,
		"platforms": [
			{"y": 299, "x1": 205,  "x2": 1042},  # mid platform
			{"y": 512, "x1": 221,  "x2": 1042},  # lower platform
		],
		"tile_color": Color(0.65, 0.48, 0.18),
	},
	"onepiece.png": {
		"floor_y":   683,
		"spawn_y":   430,
		"platforms": [
			{"y": 293, "x1":   7,  "x2":  430},  # top-left
			{"y": 293, "x1": 851,  "x2": 1271},  # top-right
			{"y": 440, "x1":   7,  "x2": 1271},  # wide mid
			{"y": 573, "x1":   7,  "x2": 1271},  # lower
		],
		"tile_color": Color(0.55, 0.35, 0.14),
	},
	"bleach.png": {
		"floor_y":   691,
		"spawn_y":   450,
		"platforms": [
			{"y": 299, "x1": 265,  "x2": 1075},  # upper mid
			{"y": 464, "x1":   8,  "x2": 1268},  # wide lower
			{"y": 590, "x1": 375,  "x2":  913},  # small lower
		],
		"tile_color": Color(0.55, 0.55, 0.60),
	},
	"forest.png": {
		"floor_y":   706,
		"spawn_y":   450,
		"platforms": [
			{"y": 147, "x1":   4,  "x2": 1273},  # top
			{"y": 406, "x1":   4,  "x2": 1273},  # mid
			{"y": 573, "x1":   7,  "x2":  366},  # lower-left
			{"y": 573, "x1": 397,  "x2":  931},  # lower-mid
			{"y": 573, "x1": 962,  "x2": 1273},  # lower-right
		],
		"tile_color": Color(0.42, 0.28, 0.12),
	},
	"hunterxhunter.png": {
		"floor_y":   681,
		"spawn_y":   430,
		"platforms": [
			{"y": 293, "x1": 156,  "x2":  486},  # top-left
			{"y": 293, "x1": 791,  "x2": 1121},  # top-right
			{"y": 483, "x1": 156,  "x2": 1121},  # wide mid
		],
		"tile_color": Color(0.30, 0.22, 0.50),
	},
	"shamanking.png": {
		"floor_y":   702,
		"spawn_y":   450,
		"platforms": [
			{"y": 275, "x1": 429,  "x2": 1059},  # upper mid
			{"y": 487, "x1":  33,  "x2": 1270},  # wide mid
		],
		"tile_color": Color(0.48, 0.38, 0.24),
	},
}

static func get(stage_file: String) -> Dictionary:
	return DATA.get(stage_file, {
		"floor_y": 610, "spawn_y": 400, "platforms": [],
		"tile_color": Color(0.3, 0.2, 0.1),
	})
