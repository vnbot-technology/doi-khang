extends Object
class_name StageLayout

# Platform and floor definitions per stage.
# All positions are in 1280x720 world space (background fills viewport non-uniformly).
# Each platform entry: { y, x1, x2 }  — y is top surface of platform.

const DATA: Dictionary = {
	# floor_y values match the original Ground node position (y=610) in GameArena.tscn.
	# Platforms are positioned relative to floor_y so jump math stays consistent.
	"naruto.png": {
		"floor_y":   610,
		"spawn_y":   420,
		"platforms": [],
		"tile_color": Color(0.45, 0.32, 0.18),
	},
	"dragonball.png": {
		"floor_y":   610,
		"spawn_y":   420,
		"platforms": [
			{"y": 390, "x1": 205,  "x2": 1042},  # mid platform (~220px above floor)
			{"y": 510, "x1": 221,  "x2": 1042},  # lower platform (~100px above floor)
		],
		"tile_color": Color(0.65, 0.48, 0.18),
	},
	"onepiece.png": {
		"floor_y":   610,
		"spawn_y":   420,
		"platforms": [
			{"y": 370, "x1":   7,  "x2":  430},  # top-left
			{"y": 370, "x1": 851,  "x2": 1271},  # top-right
			{"y": 480, "x1":   7,  "x2": 1271},  # wide mid
			{"y": 550, "x1":   7,  "x2": 1271},  # lower
		],
		"tile_color": Color(0.55, 0.35, 0.14),
	},
	"bleach.png": {
		"floor_y":   610,
		"spawn_y":   420,
		"platforms": [
			{"y": 380, "x1": 265,  "x2": 1075},  # upper mid
			{"y": 490, "x1":   8,  "x2": 1268},  # wide lower
			{"y": 560, "x1": 375,  "x2":  913},  # small lower
		],
		"tile_color": Color(0.55, 0.55, 0.60),
	},
	"forest.png": {
		"floor_y":   610,
		"spawn_y":   420,
		"platforms": [
			{"y": 200, "x1":   4,  "x2": 1273},  # top
			{"y": 380, "x1":   4,  "x2": 1273},  # mid
			{"y": 500, "x1":   7,  "x2":  366},  # lower-left
			{"y": 500, "x1": 397,  "x2":  931},  # lower-mid
			{"y": 500, "x1": 962,  "x2": 1273},  # lower-right
		],
		"tile_color": Color(0.42, 0.28, 0.12),
	},
	"hunterxhunter.png": {
		"floor_y":   610,
		"spawn_y":   420,
		"platforms": [
			{"y": 370, "x1": 156,  "x2":  486},  # top-left
			{"y": 370, "x1": 791,  "x2": 1121},  # top-right
			{"y": 490, "x1": 156,  "x2": 1121},  # wide mid
		],
		"tile_color": Color(0.30, 0.22, 0.50),
	},
	"shamanking.png": {
		"floor_y":   610,
		"spawn_y":   420,
		"platforms": [
			{"y": 380, "x1": 429,  "x2": 1059},  # upper mid
			{"y": 500, "x1":  33,  "x2": 1270},  # wide mid
		],
		"tile_color": Color(0.48, 0.38, 0.24),
	},
}

static func get(stage_file: String) -> Dictionary:
	return DATA.get(stage_file, {
		"floor_y": 610, "spawn_y": 420, "platforms": [],
		"tile_color": Color(0.3, 0.2, 0.1),
	})
