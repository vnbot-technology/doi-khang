extends CharacterBase
class_name Sasuke

func _ready() -> void:
	char_name = "Sasuke"
	max_health = 105.0
	health = max_health

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.6
	# Chidori — lightning dash forward
	if attack_hitbox:
		attack_hitbox.reset()
		attack_hitbox.damage = 28.0
		attack_hitbox.knockback_force = 360.0
		attack_hitbox.scale.x = 1.0 if facing_right else -1.0
		attack_hitbox.monitoring = true
	velocity.x = (1.0 if facing_right else -1.0) * 560.0
	velocity.x = clamp(velocity.x, -500.0, 500.0)
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
	state_timer = 1.0
	# Susanoo — powerful area strike
	if attack_hitbox:
		attack_hitbox.reset()
		attack_hitbox.damage = 48.0
		attack_hitbox.knockback_force = 520.0
		attack_hitbox.scale.x = 1.0 if facing_right else -1.0
		attack_hitbox.monitoring = true
	velocity.x = (1.0 if facing_right else -1.0) * 220.0
	velocity.x = clamp(velocity.x, -500.0, 500.0)
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(attack_hitbox):
			attack_hitbox.monitoring = false
			attack_hitbox.damage = 15.0
			attack_hitbox.knockback_force = 280.0
	)
