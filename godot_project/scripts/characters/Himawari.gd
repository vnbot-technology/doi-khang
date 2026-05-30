extends CharacterBase
class_name Himawari

func _ready() -> void:
	char_name = "Himawari"
	max_health = 95.0
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
		attack_hitbox.damage = 25.0
		attack_hitbox.knockback_force = 300.0
		attack_hitbox.monitoring = true
	velocity.x += (1.0 if facing_right else -1.0) * 380.0
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
	state_timer = 0.8
	if opponent and is_instance_valid(opponent):
		var d := global_position.distance_to(opponent.global_position)
		if d < 180.0:
			opponent.take_damage(48.0, Vector2(sign(opponent.global_position.x - global_position.x) * 320.0, -140.0))
			add_special(20.0)
