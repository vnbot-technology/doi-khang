extends CharacterBase
class_name Conan

const STUN_DURATION := 1.5
const SOCCER_HITS := 5
const SOCCER_DAMAGE_PER_HIT := 12.0

func _ready() -> void:
	char_name = "Conan"
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
		if global_position.distance_to(opponent.global_position) < 200.0:
			opponent.state = CharacterBase.State.HURT
			opponent.state_timer = STUN_DURATION
			opponent.velocity.x = 0.0
			if opponent.attack_hitbox:
				opponent.attack_hitbox.monitoring = false
			if opponent.body_rect and "is_blocking" in opponent.body_rect:
				opponent.body_rect.set("is_blocking", false)
			add_special(10.0)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	_set_state(State.ULTIMATE)
	state_timer = 1.2
	var captured_opponent := opponent
	for i in range(SOCCER_HITS):
		get_tree().create_timer(float(i) * 0.2).timeout.connect(func():
			if not is_instance_valid(self):
				return
			if captured_opponent == null or not is_instance_valid(captured_opponent):
				return
			if captured_opponent.is_dead:
				return
			var dir: float = sign(captured_opponent.global_position.x - global_position.x)
			captured_opponent.take_damage(SOCCER_DAMAGE_PER_HIT, Vector2(dir * 200.0, -60.0))
			hit_landed.emit(captured_opponent, SOCCER_DAMAGE_PER_HIT)
		)
