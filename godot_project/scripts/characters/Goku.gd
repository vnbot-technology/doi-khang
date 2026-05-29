extends CharacterBase
class_name Goku

const KAMEHAMEHA_DAMAGE := 35.0
const SSJ_DURATION := 5.0

var ssj_active: bool = false
var ssj_timer: float = 0.0

func _ready() -> void:
	char_name = "Goku"
	max_health = 110.0
	health = max_health

func _physics_process(delta: float) -> void:
	if ssj_active:
		ssj_timer -= delta
		if ssj_timer <= 0.0:
			ssj_active = false
			if body_rect and "base_color" in body_rect:
				body_rect.set("base_color", Global.CHARACTER_COLORS["Goku"])
	super(delta)

func _state_crouch(delta: float) -> void:
	super(delta)
	add_special(3.0 * delta)

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.6
	_fire_kamehameha()

func _fire_kamehameha() -> void:
	if not get_parent():
		return
	var vel := Vector2(1.0 if facing_right else -1.0, 0.0) * 600.0
	var proj := _create_beam_projectile(
		Color(0.3, 0.5, 1.0),
		vel,
		KAMEHAMEHA_DAMAGE,
		Vector2(80, 20)
	)
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2((1.0 if facing_right else -1.0) * 60.0, -20.0)
	# Set velocity AFTER add_child so script is properly initialized
	proj.set("vel", vel)
	# Ensure the projectile's hitbox is monitoring (Hitbox._ready sets it to false)
	var hb := proj.get_node_or_null("Hitbox") as Hitbox
	if hb:
		hb.monitoring = true

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	ssj_active = true
	ssj_timer = SSJ_DURATION
	if body_rect and "base_color" in body_rect:
		body_rect.set("base_color", Color(1.0, 1.0, 0.0))
	_set_state(State.ULTIMATE)
	state_timer = 1.0

func _create_beam_projectile(color: Color, vel: Vector2, dmg: float, size: Vector2) -> Node2D:
	var proj := Node2D.new()
	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = -size / 2.0
	proj.add_child(rect)

	var hitbox := Hitbox.new()
	hitbox.name = "Hitbox"
	hitbox.damage = dmg
	hitbox.owner_character = self
	hitbox.knockback_force = 200.0
	var atk_col := CollisionShape2D.new()
	var atk_shape := RectangleShape2D.new()
	atk_shape.size = size
	atk_col.shape = atk_shape
	hitbox.add_child(atk_col)
	proj.add_child(hitbox)

	var script := GDScript.new()
	script.source_code = """extends Node2D
var vel: Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
	position += vel * delta
	if global_position.x < -200 or global_position.x > 1600:
		queue_free()
"""
	var err := script.reload()
	if err != OK:
		push_error("Goku projectile script failed to compile: %s" % err)
		proj.queue_free()
		return Node2D.new()
	proj.set_script(script)
	proj.set("vel", vel)
	return proj
