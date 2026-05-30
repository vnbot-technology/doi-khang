extends CharacterBase
class_name Sakura

const HEAL_AMOUNT := 15.0
const IMPACT_DAMAGE := 55.0
const REGEN_RATE := 5.0

var time_since_last_hit: float = 999.0

func _ready() -> void:
	char_name = "Sakura"
	max_health = 100.0
	health = max_health

func _physics_process(delta: float) -> void:
	time_since_last_hit += delta
	if time_since_last_hit > 3.0 and not is_dead and health < max_health:
		health = min(max_health, health + REGEN_RATE * delta)
		health_changed.emit(health, max_health)
	super(delta)

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	time_since_last_hit = 0.0
	super(amount, knockback)

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.5
	heal(HEAL_AMOUNT)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	_set_state(State.ULTIMATE)
	state_timer = 0.6
	velocity.y = 200.0
	if opponent and is_instance_valid(opponent):
		if global_position.distance_to(opponent.global_position) < 280.0:
			var dir: float = sign(opponent.global_position.x - global_position.x)
			opponent.take_damage(IMPACT_DAMAGE, Vector2(dir * 400.0, -200.0))
			hit_landed.emit(opponent, IMPACT_DAMAGE)
	add_special(20.0)
