extends Node
class_name AIController

enum Difficulty { EASY, MEDIUM, HARD }
enum AIState { APPROACH, ATTACK, RETREAT }

@export var difficulty: Difficulty = Difficulty.MEDIUM

var controlled_char: CharacterBase = null
var action_timer: float = 0.0

const REACTION_TIMES: Dictionary = {
	0: 0.5,
	1: 0.2,
	2: 0.08,
}
const ATTACK_RANGE := 180.0
const APPROACH_RANGE := 400.0

func setup(character: CharacterBase) -> void:
	controlled_char = character
	controlled_char.is_local = false

func _process(delta: float) -> void:
	if controlled_char == null or not is_instance_valid(controlled_char) or controlled_char.is_dead:
		return
	action_timer -= delta
	if action_timer > 0.0:
		return
	action_timer = REACTION_TIMES[int(difficulty)] + randf() * 0.1
	_decide_action()

func _decide_action() -> void:
	var opp := controlled_char.opponent
	if opp == null or not is_instance_valid(opp) or opp.is_dead:
		return
	var dist := controlled_char.global_position.distance_to(opp.global_position)
	if dist < ATTACK_RANGE and _is_facing_opponent():
		_execute_attack()
	else:
		_execute_approach(opp)

func _execute_approach(opp: CharacterBase) -> void:
	var dir := sign(opp.global_position.x - controlled_char.global_position.x)
	controlled_char.velocity.x = dir * CharacterBase.MOVE_SPEED * 0.9
	controlled_char.state = CharacterBase.State.WALK

func _execute_attack() -> void:
	var roll := randf()
	if controlled_char.special >= 80.0 and difficulty == Difficulty.HARD and roll < 0.3:
		controlled_char._do_ultimate()
	elif controlled_char.special >= 30.0 and roll < 0.45:
		controlled_char._do_special()
	else:
		controlled_char._do_attack()

func _is_facing_opponent() -> bool:
	if controlled_char.opponent == null:
		return false
	var diff := controlled_char.opponent.global_position.x - controlled_char.global_position.x
	return (diff > 0.0) == controlled_char.facing_right
