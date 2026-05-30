extends Node
class_name GameManager

signal round_started(round_num: int)
signal round_ended(winner_id: int)
signal match_ended(winner_id: int)
signal timer_updated(seconds: float)

const ROUND_TIME := 90.0
const MAX_ROUNDS := 3

var current_round: int = 1
var round_wins: Dictionary = {1: 0, 2: 0}
var round_timer: float = ROUND_TIME
var round_active: bool = false
var players: Array[CharacterBase] = []

func _ready() -> void:
	set_process(false)

func start_match(p_players: Array[CharacterBase]) -> void:
	players = p_players
	current_round = 1
	round_wins = {1: 0, 2: 0}
	for p in players:
		p.died.connect(_on_player_died.bind(p))
	_start_round()

func _start_round() -> void:
	round_timer = ROUND_TIME
	round_active = true
	set_process(true)
	for p in players:
		p.revive()
	_reset_positions()
	round_started.emit(current_round)

func _reset_positions() -> void:
	if players.size() >= 2:
		players[0].global_position = Vector2(300.0, 420.0)
		players[1].global_position = Vector2(980.0, 420.0)
		players[0].facing_right = true
		if players[0].body_rect:
			players[0].body_rect.scale.x = 1.0
		players[1].facing_right = false
		if players[1].body_rect:
			players[1].body_rect.scale.x = -1.0

func _process(delta: float) -> void:
	if not round_active:
		return
	round_timer -= delta
	timer_updated.emit(round_timer)
	if round_timer <= 0.0:
		_end_round_timeout()

func _on_player_died(_player: CharacterBase) -> void:
	if not round_active:
		return
	var winner_id := _get_alive_player_id()
	_end_round(winner_id)

func _end_round_timeout() -> void:
	var winner_id := _get_highest_hp_player_id()
	_end_round(winner_id)

func _end_round(winner_id: int) -> void:
	round_active = false
	set_process(false)
	if winner_id > 0:
		round_wins[winner_id] = round_wins.get(winner_id, 0) + 1
	round_ended.emit(winner_id)
	var wins_needed := 2
	if winner_id > 0 and round_wins.get(winner_id, 0) >= wins_needed:
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(self) and not is_queued_for_deletion():
				match_ended.emit(winner_id)
		)
	elif current_round < MAX_ROUNDS:
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(self) and not is_queued_for_deletion():
				current_round += 1
				_start_round()
		)
	else:
		var final_winner := _get_most_wins()
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(self) and not is_queued_for_deletion():
				match_ended.emit(final_winner)
		)

func _get_alive_player_id() -> int:
	for p in players:
		if not p.is_dead:
			return p.player_id
	return 0

func _get_highest_hp_player_id() -> int:
	var best_id := 0
	var best_hp := -1.0
	for p in players:
		if not p.is_dead and p.health > best_hp:
			best_hp = p.health
			best_id = p.player_id
	return best_id

func _get_most_wins() -> int:
	var best_id := 0
	var best_wins := -1
	for pid in round_wins:
		if round_wins[pid] > best_wins:
			best_wins = round_wins[pid]
			best_id = pid
	return best_id
