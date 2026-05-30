extends CharacterBase
class_name Shino

func _ready() -> void:
	char_name = "Shino"
	max_health = 95.0
	health = max_health

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.5
	if attack_hitbox:
		attack_hitbox.reset()
		attack_hitbox.scale.x = 1.0 if facing_right else -1.0
		attack_hitbox.monitoring = true
	velocity.x += (1.0 if facing_right else -1.0) * 300.0
			attack_hitbox.damage = 22.0; attack_hitbox.knockback_force = 300.0
	get_tree().create_timer(0.4).timeout.connect(func():
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
	state_timer = 1.2
	if opponent and is_instance_valid(opponent):
				var dir := sign(opponent.global_position.x - global_position.x)
				for i in range(8):
					get_tree().create_timer(float(i)*0.12).timeout.connect(func():
						if is_instance_valid(self) and is_instance_valid(opponent) and not opponent.is_dead:
							opponent.take_damage(8.0, Vector2(dir*60.0, 0.0)))
