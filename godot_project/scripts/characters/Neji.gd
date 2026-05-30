extends CharacterBase
class_name Neji

func _ready() -> void:
	char_name = "Neji"
	max_health = 100.0
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
		attack_hitbox.damage = 26.0
		attack_hitbox.knockback_force = 340.0
		attack_hitbox.monitoring = true
	velocity.x += (1.0 if facing_right else -1.0) * 360.0
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
	state_timer = 0.9
	if attack_hitbox:
		attack_hitbox.reset()
		attack_hitbox.scale.x = 1.0
		attack_hitbox.damage = 52.0
		attack_hitbox.knockback_force = 500.0
		attack_hitbox.monitoring = true
	velocity.y = -120.0
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(attack_hitbox):
			attack_hitbox.monitoring = false
			attack_hitbox.damage = 15.0
			attack_hitbox.knockback_force = 280.0
	)
