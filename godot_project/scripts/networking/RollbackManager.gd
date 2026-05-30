extends Node
class_name RollbackManager

const BUFFER_SIZE := 8

var input_history: Dictionary = {}
var current_frame: int = 0
var local_peer_id: int = 1
var remote_peer_id: int = 2
var _last_remote_frame: int = -1

# Tracks whether each ring-buffer slot holds an authoritative remote input
# (true) versus a leftover/predicted value (false). Indexed by frame % BUFFER_SIZE.
var _frames_received: Array[bool] = []

func setup(local_id: int, remote_id: int) -> void:
	local_peer_id = local_id
	remote_peer_id = remote_id
	input_history[local_id] = []
	input_history[remote_id] = []
	for i in range(BUFFER_SIZE):
		input_history[local_id].append(0)
		input_history[remote_id].append(0)
	current_frame = 0
	_last_remote_frame = -1
	_frames_received.clear()
	for i in range(BUFFER_SIZE):
		_frames_received.append(false)

func collect_and_send_input(local_input: int) -> void:
	var buf_idx := current_frame % BUFFER_SIZE
	input_history[local_peer_id][buf_idx] = local_input
	if multiplayer.has_multiplayer_peer():
		receive_remote_input.rpc(current_frame, local_input)

@rpc("any_peer", "unreliable_ordered")
func receive_remote_input(frame: int, input_bitmask: int) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != remote_peer_id:
		return
	# Drop stale packets — `unreliable_ordered` drops most out-of-order,
	# but a delayed frame can still collide with the ring buffer (frame % BUFFER_SIZE).
	if frame <= _last_remote_frame:
		return
	_last_remote_frame = frame
	var buf_idx := frame % BUFFER_SIZE
	if input_history.has(sender):
		input_history[sender][buf_idx] = input_bitmask
		# Mark this slot as carrying an authoritative remote input so we
		# don't fall back to "predict previous frame" when the opponent is
		# genuinely idle (bitmask 0 == no keys pressed, which is valid).
		_frames_received[buf_idx] = true

func get_inputs_for_frame(frame: int) -> Array[int]:
	var buf_idx := frame % BUFFER_SIZE
	var local_in: int = input_history[local_peer_id][buf_idx]
	var remote_in: int = input_history[remote_peer_id][buf_idx]
	# Only predict (reuse previous frame) when this slot has NOT been
	# filled by an actual remote packet. A received value of 0 is valid
	# input ("standing still"), not a missing packet.
	if not _frames_received[buf_idx] and frame > 0:
		var prev_idx := (frame - 1) % BUFFER_SIZE
		remote_in = input_history[remote_peer_id][prev_idx]
	# Untyped array literals don't auto-cast to Array[int] in Godot 4 — build explicitly.
	var result: Array[int] = [local_in, remote_in]
	return result

func advance_frame() -> void:
	# Clear the received flag for the slot that's about to be recycled
	# BUFFER_SIZE frames from now. Doing it here (rather than in
	# get_inputs_for_frame) keeps the flag valid across multiple reads
	# of the same frame (e.g. rollback resimulation).
	_frames_received[current_frame % BUFFER_SIZE] = false
	current_frame += 1
