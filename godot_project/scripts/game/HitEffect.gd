extends Node2D
class_name HitEffect

# Tiny burst of colored sparks spawned at hit location.
# Call HitEffect.spawn(parent, pos, color, scale) to create one.

const PARTICLE_COUNT := 8
const LIFETIME := 0.3

var _particles: Array = []   # each: {pos, vel, color, alpha}
var _elapsed: float = 0.0

static func spawn(parent: Node, pos: Vector2, hit_color: Color, intensity: float = 1.0) -> void:
	var fx := HitEffect.new()
	fx.global_position = pos
	parent.add_child(fx)
	fx._init_particles(hit_color, intensity)

func _init_particles(hit_color: Color, intensity: float) -> void:
	var count := int(PARTICLE_COUNT * intensity)
	for i in range(count):
		var angle := (float(i) / count) * TAU + randf() * 0.5
		var speed := (60.0 + randf() * 80.0) * intensity
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": hit_color.lightened(randf() * 0.3),
			"alpha": 1.0,
		})

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= LIFETIME:
		queue_free()
		return
	var t := _elapsed / LIFETIME
	for p in _particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.85
		p["alpha"] = 1.0 - t
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		var c: Color = p["color"]
		c.a = p["alpha"]
		draw_circle(p["pos"], 3.5, c)
		draw_circle(p["pos"] + p["vel"] * -0.04, 2.0, c * Color(1,1,1,0.4))
