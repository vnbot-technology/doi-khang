extends CharacterBody2D
class_name CharacterBase

signal health_changed(new_hp: float, max_hp: float)
signal special_changed(new_sp: float)
signal died
signal hit_landed(target: CharacterBase, damage: float)

const GRAVITY := 980.0
const JUMP_VELOCITY := -480.0
const MOVE_SPEED := 220.0

@export var char_name: String = "Base"
@export var max_health: float = 100.0
@export var max_special: float = 100.0

var health: float = 100.0
var special: float = 0.0
var player_id: int = 1
var input_prefix: String = "p1_"
var is_local: bool = true
var opponent: CharacterBase = null

var facing_right: bool = true
var is_dead: bool = false

# Optional input override (used by AIController). When >= 0, replaces local input.
# AI sets this each tick via set_input_override(); CharacterBase reads it in _get_input().
var input_override: int = -1

enum State {
	IDLE, WALK, JUMP, CROUCH,
	ATTACK, SPECIAL, ULTIMATE,
	HURT, DEAD, BLOCK
}
var state: State = State.IDLE
var state_timer: float = 0.0

var body_rect: Node2D = null  # CharacterSprite (custom-drawn) — kept name for backward compat
var attack_hitbox: Hitbox = null
var hurtbox: Hurtbox = null

func setup(pid: int, prefix: String, local: bool) -> void:
	player_id = pid
	input_prefix = prefix
	is_local = local
	health = max_health
	special = 0.0
	if body_rect:
		body_rect.set("base_color", Global.CHARACTER_COLORS.get(char_name, Color.WHITE))
		body_rect.set("char_name", char_name)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_apply_gravity(delta)
	state_timer -= delta
	add_special(8.0 * delta)
	_process_state(delta)
	move_and_slide()
	_clamp_to_arena()
	_face_opponent()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

func _clamp_to_arena() -> void:
	position.x = clamp(position.x, 80.0, 1200.0)

func _face_opponent() -> void:
	if opponent and is_instance_valid(opponent) and state not in [State.ATTACK, State.SPECIAL, State.ULTIMATE, State.HURT]:
		var diff := opponent.global_position.x - global_position.x
		if diff > 5.0:
			facing_right = true
			if body_rect:
				body_rect.scale.x = 1.0
		elif diff < -5.0:
			facing_right = false
			if body_rect:
				body_rect.scale.x = -1.0

func _process_state(delta: float) -> void:
	match state:
		State.IDLE:     _state_idle(delta)
		State.WALK:     _state_walk(delta)
		State.JUMP:     _state_jump(delta)
		State.CROUCH:   _state_crouch(delta)
		State.ATTACK:   _state_attack(delta)
		State.SPECIAL:  _state_special(delta)
		State.ULTIMATE: _state_ultimate(delta)
		State.HURT:     _state_hurt(delta)
		State.BLOCK:    _state_block(delta)

func _get_input() -> int:
	if input_override >= 0:
		return input_override
	if is_local:
		return Global.get_input_bitmask(input_prefix)
	return 0

func set_input_override(bits: int) -> void:
	input_override = bits

func _state_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, MOVE_SPEED * 8 * delta)
	var input := _get_input()
	_check_combat_input(input)
	if state != State.IDLE:
		return
	if input & 1:   _set_state(State.WALK)
	elif input & 2: _set_state(State.WALK)
	elif (input & 4) and is_on_floor(): _jump()
	elif input & 8: _set_state(State.CROUCH)
	elif input & 128: _set_state(State.BLOCK)

func _state_walk(delta: float) -> void:
	var input := _get_input()
	_check_combat_input(input)
	if state != State.WALK:
		return
	if input & 1:
		velocity.x = -MOVE_SPEED
	elif input & 2:
		velocity.x = MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED * 8 * delta)
		_set_state(State.IDLE)
	if (input & 4) and is_on_floor(): _jump()
	if input & 8: _set_state(State.CROUCH)

func _state_jump(_delta: float) -> void:
	var input := _get_input()
	if input & 1:   velocity.x = -MOVE_SPEED * 0.8
	elif input & 2: velocity.x = MOVE_SPEED * 0.8
	_check_combat_input(input)
	if is_on_floor():
		_set_state(State.IDLE)

func _state_crouch(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, MOVE_SPEED * 12 * delta)
	var input := _get_input()
	if not (input & 8):
		_set_state(State.IDLE)
	_check_combat_input(input)

func _state_attack(_delta: float) -> void:
	if state_timer <= 0.0:
		if attack_hitbox:
			attack_hitbox.monitoring = false
		_set_state(State.IDLE)

func _state_special(_delta: float) -> void:
	if state_timer <= 0.0:
		_set_state(State.IDLE)

func _state_ultimate(_delta: float) -> void:
	if state_timer <= 0.0:
		_set_state(State.IDLE)

func _state_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 400.0 * delta)
	if state_timer <= 0.0:
		_set_state(State.IDLE)

func _state_block(_delta: float) -> void:
	velocity.x = 0.0
	var input := _get_input()
	if not (input & 128):
		_set_state(State.IDLE)

func _check_combat_input(input: int) -> void:
	if state in [State.ATTACK, State.SPECIAL, State.ULTIMATE, State.HURT, State.DEAD]:
		return
	if input & 16:
		_do_attack()
	elif (input & 32) and special >= 30.0:
		_do_special()
		if state == State.SPECIAL:
			_flash_color(Color(0.3, 0.8, 1.0), 0.4)
			if body_rect and "is_attacking" in body_rect:
				body_rect.set("is_attacking", true)
				get_tree().create_timer(0.5).timeout.connect(func():
					if is_instance_valid(self) and is_instance_valid(body_rect):
						body_rect.set("is_attacking", false)
				)
	elif (input & 64) and special >= 50.0:
		_do_ultimate()
		if state == State.ULTIMATE:
			_flash_color(Color(1.0, 0.85, 0.0), 0.6)
			if body_rect and "is_attacking" in body_rect:
				body_rect.set("is_attacking", true)
				get_tree().create_timer(0.9).timeout.connect(func():
					if is_instance_valid(self) and is_instance_valid(body_rect):
						body_rect.set("is_attacking", false)
				)

func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	_set_state(State.JUMP)

func _do_attack() -> void:
	_set_state(State.ATTACK)
	state_timer = 0.3
	if attack_hitbox:
		attack_hitbox.reset()
		attack_hitbox.scale.x = 1.0 if facing_right else -1.0
		attack_hitbox.monitoring = true
	velocity.x += (1.0 if facing_right else -1.0) * 180.0
	# Trigger attack pose on sprite
	if body_rect and "is_attacking" in body_rect:
		body_rect.set("is_attacking", true)
		get_tree().create_timer(0.2).timeout.connect(func():
			if is_instance_valid(self) and is_instance_valid(body_rect):
				body_rect.set("is_attacking", false)
		)
	var base: Color = Color.WHITE
	if body_rect and "base_color" in body_rect:
		base = body_rect.get("base_color")
	_flash_color(base.lightened(0.5), 0.15)
	get_tree().create_timer(0.15).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(attack_hitbox):
			attack_hitbox.monitoring = false
	)

func _do_special() -> void:
	pass

func _do_ultimate() -> void:
	pass

func _set_state(new_state: State) -> void:
	state = new_state
	state_timer = 0.0
	if body_rect and "is_blocking" in body_rect:
		body_rect.set("is_blocking", new_state == State.BLOCK)

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	if state == State.BLOCK:
		amount *= 0.15
		health = max(0.0, health - amount)
		velocity.x += knockback.x * 0.3
		velocity.y = max(velocity.y + knockback.y * 0.3, -120.0)
	else:
		health = max(0.0, health - amount)
		velocity.x += knockback.x
		velocity.y = max(knockback.y, -160.0)
		if state not in [State.ATTACK, State.SPECIAL, State.ULTIMATE]:
			_set_state(State.HURT)
			state_timer = 0.35
	add_special(amount * 0.5)
	_flash_color(Color.RED, 0.2)
	health_changed.emit(health, max_health)
	if health <= 0.0 and not is_dead:
		_die()

func add_special(amount: float) -> void:
	special = min(max_special, special + amount)
	special_changed.emit(special)

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func revive() -> void:
	health = max_health
	is_dead = false
	state = State.IDLE
	state_timer = 0.0
	velocity = Vector2.ZERO
	if body_rect is CharacterSprite:
		(body_rect as CharacterSprite).is_dead = false
		(body_rect as CharacterSprite).is_attacking = false
		(body_rect as CharacterSprite).is_blocking = false
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.reset()
	health_changed.emit(health, max_health)
	special_changed.emit(special)

func _die() -> void:
	is_dead = true
	state = State.DEAD
	velocity = Vector2.ZERO
	if body_rect and "is_dead" in body_rect:
		body_rect.set("is_dead", true)
	died.emit()

func _flash_color(flash: Color, duration: float) -> void:
	if not body_rect:
		return
	if body_rect.has_method("flash"):
		body_rect.flash(flash, duration)
