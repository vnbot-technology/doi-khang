extends CharacterBase
class_name Luffy

const PISTOL_DAMAGE := 22.0
const GEAR2_DURATION := 8.0

var gear2_active: bool = false
var gear2_timer: float = 0.0

func _ready() -> void:
	char_name = "Luffy"
	max_health = 120.0
	health = max_health

func _physics_process(delta: float) -> void:
	if gear2_active:
		gear2_timer -= delta
		if gear2_timer <= 0.0:
			gear2_active = false
			if body_rect and "base_color" in body_rect:
				body_rect.set("base_color", Global.CHARACTER_COLORS["Luffy"])
	super(delta)

func _do_special() -> void:
	if special < 30.0:
		return
	special -= 30.0
	special_changed.emit(special)
	_set_state(State.SPECIAL)
	state_timer = 0.4
	if opponent and is_instance_valid(opponent):
		var dist := global_position.distance_to(opponent.global_position)
		if dist < 320.0:
			var dmg := PISTOL_DAMAGE * (1.2 if gear2_active else 1.0)
			var dir: float = sign(opponent.global_position.x - global_position.x)
			opponent.take_damage(dmg, Vector2(dir * 350.0, -80.0))
			hit_landed.emit(opponent, dmg)
			add_special(5.0)

func _do_ultimate() -> void:
	if special < 50.0:
		return
	special -= 50.0
	special_changed.emit(special)
	gear2_active = true
	gear2_timer = GEAR2_DURATION
	if body_rect and "base_color" in body_rect:
		body_rect.set("base_color", Color(1.0, 0.4, 0.4))
	_set_state(State.ULTIMATE)
	state_timer = 0.8
