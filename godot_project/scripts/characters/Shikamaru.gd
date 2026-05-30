extends CharacterBase
class_name Shikamaru

func _ready() -> void:
	char_name = "Shikamaru"
	max_health = 90.0
	health = max_health

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.4
	if opponent and is_instance_valid(opponent):
		opponent.state = CharacterBase.State.HURT
		opponent.state_timer = 1.2
		opponent.velocity.x = 0.0

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	_set_state(State.ULTIMATE)
	state_timer = 1.0
	if opponent and is_instance_valid(opponent):
		for i in range(6):
			get_tree().create_timer(float(i) * 0.15).timeout.connect(func():
				if is_instance_valid(self) and is_instance_valid(opponent) and not opponent.is_dead:
					opponent.take_damage(10.0, Vector2.ZERO)
			)
