extends Node
class_name AIController

enum Difficulty { EASY, MEDIUM, HARD }
enum AIState { APPROACH, ATTACK, RETREAT }

@export var difficulty: Difficulty = Difficulty.MEDIUM

var controlled_char: CharacterBase = null
var action_timer: float = 0.0
var _current_input: int = 0

# Defensive / reactive state
var _prev_health: float = -1.0
var _block_timer: float = 0.0
var _retreat_timer: float = 0.0

const REACTION_TIMES: Dictionary = {
	0: 0.35,   # EASY
	1: 0.10,   # MEDIUM — was 0.2, felt too passive
	2: 0.04,   # HARD
}
const ATTACK_RANGE := 180.0
const APPROACH_RANGE := 400.0
const LOW_HP_RATIO := 0.25
const DAMAGE_REACT_THRESHOLD := 2.0

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
		# Seed health tracking so the first frame doesn't register a false damage event.
		_prev_health = controlled_char.health

func _process(delta: float) -> void:
	if controlled_char == null or not is_instance_valid(controlled_char):
		return
	if controlled_char.is_dead:
		controlled_char.set_input_override(0)
		return

	# Decay "just-pressed" bits (attack/jump/special/ultimate) every tick so
	# they fire exactly once per decision, matching is_action_just_pressed semantics.
	# Block is also a pulse-like state we manage explicitly via _block_timer.
	_current_input &= ~(IN_JUMP | IN_ATTACK | IN_SPECIAL | IN_ULTIMATE | IN_BLOCK)

	# Reactive blocking: detect health drop and trigger a short block window.
	if _prev_health < 0.0:
		_prev_health = controlled_char.health
	elif controlled_char.health < _prev_health - DAMAGE_REACT_THRESHOLD:
		var react_block: float = [0.2, 0.4, 0.7][int(difficulty)]
		if randf() < react_block:
			_block_timer = 0.25 + randf() * 0.25
	_prev_health = controlled_char.health

	# Active block window: hold block, drop offensive bits, skip decision this frame.
	if _block_timer > 0.0:
		_block_timer -= delta
		_current_input |= IN_BLOCK
		_current_input &= ~(IN_ATTACK | IN_SPECIAL | IN_ULTIMATE)
		controlled_char.set_input_override(_current_input)
		return

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

	# Low-health defensive: if cornered close and hurt, back off (except EASY).
	var hp_ratio: float = 1.0
	if controlled_char.max_health > 0.0:
		hp_ratio = controlled_char.health / controlled_char.max_health
	if hp_ratio < LOW_HP_RATIO and dist < ATTACK_RANGE and difficulty != Difficulty.EASY:
		_retreat(opp)
		return

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
	# Randomly jump during approach to mix up the rush and dodge pokes.
	# Higher chance at HARD difficulty.
	var jump_chance: float = [0.02, 0.05, 0.12][int(difficulty)]
	if controlled_char.is_on_floor() and randf() < jump_chance:
		_current_input |= IN_JUMP

func _retreat(opp: CharacterBase) -> void:
	# Move away from opponent, occasionally hop back for spacing.
	_current_input &= ~(IN_LEFT | IN_RIGHT)
	var dir := -sign(opp.global_position.x - controlled_char.global_position.x)
	if dir < 0:
		_current_input |= IN_LEFT
	elif dir > 0:
		_current_input |= IN_RIGHT
	if controlled_char.is_on_floor() and randf() < 0.3:
		_current_input |= IN_JUMP

func _execute_attack(_opp: CharacterBase) -> void:
	if controlled_char == null or not is_instance_valid(controlled_char):
		return
	# Stop moving while attacking
	_current_input &= ~(IN_LEFT | IN_RIGHT)
	var roll := randf()
	match difficulty:
		Difficulty.EASY:
			if controlled_char.special >= 90.0 and roll < 0.15:
				_current_input |= IN_ULTIMATE
			elif controlled_char.special >= 30.0 and roll < 0.25:
				_current_input |= IN_SPECIAL
			else:
				_current_input |= IN_ATTACK
		Difficulty.MEDIUM:
			if controlled_char.special >= 65.0 and roll < 0.25:
				_current_input |= IN_ULTIMATE
			elif controlled_char.special >= 30.0 and roll < 0.45:
				_current_input |= IN_SPECIAL
			else:
				_current_input |= IN_ATTACK
		Difficulty.HARD:
			if controlled_char.special >= 55.0 and roll < 0.45:
				_current_input |= IN_ULTIMATE
			elif controlled_char.special >= 30.0 and roll < 0.6:
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
