extends CharacterBase
class_name Doraemon

const COPTER_DURATION := 3.0

var copter_active: bool = false
var copter_timer: float = 0.0

func _ready() -> void:
	char_name = "Doraemon"
	max_health = 95.0
	health = max_health

func _physics_process(delta: float) -> void:
	if copter_active:
		copter_timer -= delta
		if copter_timer <= 0.0:
			copter_active = false
	super(delta)

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.3
	if opponent and is_instance_valid(opponent):
		var target_x := opponent.global_position.x + (1.0 if not facing_right else -1.0) * 80.0
		global_position.x = clamp(target_x, 80.0, 1200.0)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	copter_active = true
	copter_timer = COPTER_DURATION
	_set_state(State.ULTIMATE)
	state_timer = COPTER_DURATION
	if attack_hitbox:
		var original_damage := attack_hitbox.damage
		attack_hitbox.reset()
		attack_hitbox.damage = 25.0
		attack_hitbox.monitoring = true
		get_tree().create_timer(COPTER_DURATION).timeout.connect(func():
			if is_instance_valid(self) and is_instance_valid(attack_hitbox):
				attack_hitbox.monitoring = false
				attack_hitbox.damage = original_damage
		)
