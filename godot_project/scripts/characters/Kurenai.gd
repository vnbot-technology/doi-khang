extends CharacterBase
class_name Kurenai

func _ready() -> void:
	char_name = "Kurenai"
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
		opponent.state_timer = 1.8
		opponent.velocity.x = 0.0
		if opponent.body_rect and "is_blocking" in opponent.body_rect:
			opponent.body_rect.set("is_blocking", false)
		add_special(10.0)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	_set_state(State.ULTIMATE)
	state_timer = 1.0
	if opponent and is_instance_valid(opponent):
		opponent.state = CharacterBase.State.HURT
		opponent.state_timer = 2.2
		opponent.velocity = Vector2.ZERO
		if opponent.body_rect and "is_blocking" in opponent.body_rect:
			opponent.body_rect.set("is_blocking", false)
		opponent.take_damage(20.0, Vector2.ZERO)
