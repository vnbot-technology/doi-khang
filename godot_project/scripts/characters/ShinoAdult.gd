extends CharacterBase
class_name ShinoAdult

func _ready() -> void:
	char_name = "Shino Adult"
	max_health = 100.0
	health = max_health

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.4
	if attack_hitbox:
		attack_hitbox.reset()
		attack_hitbox.scale.x = 1.0 if facing_right else -1.0
		attack_hitbox.damage = 24.0
		attack_hitbox.knockback_force = 310.0
		attack_hitbox.monitoring = true
	velocity.x += (1.0 if facing_right else -1.0) * 320.0
	velocity.x = clamp(velocity.x, -500.0, 500.0)
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(attack_hitbox):
			attack_hitbox.monitoring = false
			attack_hitbox.damage = 15.0
			attack_hitbox.knockback_force = 280.0
	)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	_set_state(State.ULTIMATE)
	state_timer = 1.1
	if opponent and is_instance_valid(opponent):
		var dir := sign(opponent.global_position.x - global_position.x)
		var captured := opponent
		for i in range(10):
			get_tree().create_timer(float(i) * 0.1).timeout.connect(func():
				if is_instance_valid(self) and is_instance_valid(captured) and not captured.is_dead:
					captured.take_damage(7.0, Vector2(dir * 50.0, 0.0))
					hit_landed.emit(captured, 7.0)
			)
