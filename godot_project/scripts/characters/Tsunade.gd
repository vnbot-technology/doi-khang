extends CharacterBase
class_name Tsunade

func _ready() -> void:
	char_name = "Tsunade"
	max_health = 120.0
	health = max_health
	weight = 1.3

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.5
	heal(25.0)
	add_special(15.0)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	_set_state(State.ULTIMATE)
	state_timer = 0.8
	if opponent and is_instance_valid(opponent):
		var dir: float = sign(opponent.global_position.x - global_position.x)
		opponent.take_damage(60.0, Vector2(dir * 500.0, -200.0))
		hit_landed.emit(opponent, 60.0)
