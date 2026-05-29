extends CharacterBase
class_name Naruto

const RASENGAN_DAMAGE := 40.0
const CLONE_COUNT := 2
const CLONE_DURATION := 5.0

var clones: Array[Node] = []
var clone_timer: float = 0.0

func _ready() -> void:
	char_name = "Naruto"
	max_health = 100.0
	health = max_health

func _physics_process(delta: float) -> void:
	if clones.size() > 0:
		clone_timer -= delta
		if clone_timer <= 0.0:
			_destroy_clones()
	super(delta)

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.5
	velocity.x = (1.0 if facing_right else -1.0) * 400.0
	if attack_hitbox:
		var original_damage := attack_hitbox.damage
		attack_hitbox.reset()
		attack_hitbox.scale.x = 1.0 if facing_right else -1.0
		attack_hitbox.damage = RASENGAN_DAMAGE
		attack_hitbox.monitoring = true
		get_tree().create_timer(0.25).timeout.connect(func():
			if is_instance_valid(self) and is_instance_valid(attack_hitbox):
				attack_hitbox.monitoring = false
				attack_hitbox.damage = original_damage
		)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	_set_state(State.ULTIMATE)
	state_timer = 1.0
	_destroy_clones()
	_spawn_clones()

func _spawn_clones() -> void:
	clone_timer = CLONE_DURATION
	for i in range(CLONE_COUNT):
		var clone := _make_clone(i)
		if get_parent():
			get_parent().add_child(clone)
			clones.append(clone)

func _make_clone(index: int) -> Node2D:
	var clone := Node2D.new()
	var rect := ColorRect.new()
	var c := Global.CHARACTER_COLORS.get("Naruto", Color.YELLOW)
	rect.color = Color(c.r, c.g, c.b, 0.55)
	rect.size = Vector2(40, 80)
	rect.position = Vector2(-20, -80)
	clone.add_child(rect)
	var offset := float(index + 1) * 65.0 * (1.0 if facing_right else -1.0)
	clone.global_position = global_position + Vector2(offset, 0.0)
	return clone

func _destroy_clones() -> void:
	for c in clones:
		if is_instance_valid(c):
			c.queue_free()
	clones.clear()
