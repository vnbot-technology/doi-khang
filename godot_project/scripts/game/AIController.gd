extends Node
class_name AIController

enum Difficulty { EASY, MEDIUM, HARD }
enum AIState { APPROACH, ATTACK, RETREAT }

@export var difficulty: Difficulty = Difficulty.MEDIUM

var controlled_char: CharacterBase = null
var action_timer: float = 0.0
var _current_input: int = 0

const REACTION_TIMES: Dictionary = {
	0: 0.5,
	1: 0.2,
	2: 0.08,
}
const ATTACK_RANGE := 180.0
const APPROACH_RANGE := 400.0

# Input bits (must match Global.get_input_bitmask)
const IN_LEFT := 1
const IN_RIGHT := 2
const IN_JUMP := 4
const IN_CROUCH := 8
const IN_ATTACK := 16
const IN_SPECIAL := 32
const IN_ULTIMATE := 64
const IN_BLOCK := 128

func setup(character: CharacterBase) -> void:
	controlled_char = character
	if controlled_char:
		controlled_char.is_local = false
		controlled_char.set_input_override(0)

func _process(delta: float) -> void:
	if controlled_char == null or not is_instance_valid(controlled_char):
		return
	if controlled_char.is_dead:
		controlled_char.set_input_override(0)
		return

	# Decay "just-pressed" bits (attack/jump/special/ultimate) every tick so
	# they fire exactly once per decision, matching is_action_just_pressed semantics.
	_current_input &= ~(IN_JUMP | IN_ATTACK | IN_SPECIAL | IN_ULTIMATE)

	action_timer -= delta
	if action_timer <= 0.0:
		var key: int = int(difficulty)
		var reaction: float = REACTION_TIMES.get(key, 0.2)
		action_timer = reaction + randf() * 0.1
		_decide_action()

	controlled_char.set_input_override(_current_input)

func _decide_action() -> void:
	if controlled_char == null or not is_instance_valid(controlled_char):
		return
	var opp: CharacterBase = controlled_char.opponent
	if opp == null or not is_instance_valid(opp) or opp.is_dead:
		# Stand still
		_current_input &= ~(IN_LEFT | IN_RIGHT)
		return

	var dist := controlled_char.global_position.distance_to(opp.global_position)
	if dist < ATTACK_RANGE and _is_facing_opponent():
		_execute_attack(opp)
	else:
		_execute_approach(opp)

func _execute_approach(opp: CharacterBase) -> void:
	# Clear directional bits, then set toward opponent
	_current_input &= ~(IN_LEFT | IN_RIGHT)
	var dir := sign(opp.global_position.x - controlled_char.global_position.x)
	if dir < 0:
		_current_input |= IN_LEFT
	elif dir > 0:
		_current_input |= IN_RIGHT

func _execute_attack(_opp: CharacterBase) -> void:
	if controlled_char == null or not is_instance_valid(controlled_char):
		return
	# Stop moving while attacking
	_current_input &= ~(IN_LEFT | IN_RIGHT)
	var roll := randf()
	if controlled_char.special >= 80.0 and difficulty == Difficulty.HARD and roll < 0.3:
		_current_input |= IN_ULTIMATE
	elif controlled_char.special >= 30.0 and roll < 0.45:
		_current_input |= IN_SPECIAL
	else:
		_current_input |= IN_ATTACK

func _is_facing_opponent() -> bool:
	if controlled_char == null or not is_instance_valid(controlled_char):
		return false
	var opp: CharacterBase = controlled_char.opponent
	if opp == null or not is_instance_valid(opp):
		return false
	var diff := opp.global_position.x - controlled_char.global_position.x
	return (diff > 0.0) == controlled_char.facing_right
