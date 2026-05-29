# DoiKhang Anime Fighting Game — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable 2D anime fighting game with 5+ characters, 1v1/2v2 game modes, LAN and internet multiplayer using Godot 4 (GDScript) and a Node.js relay server.

**Architecture:** Godot 4 GDScript client using CharacterBody2D + state machines for characters, ENetMultiplayerPeer for host-client networking with 8-frame rollback input buffer, Node.js WebSocket relay server forwards packets for internet play without touching game logic. Placeholder colored-rectangle visuals for MVP (replace with sprites later).

**Tech Stack:** Godot 4.3 (GDScript), ENetMultiplayerPeer, Node.js 20, `ws` npm package.

---

## File Map

| File | Purpose |
|------|---------|
| `godot_project/project.godot` | Engine config, window, autoloads |
| `godot_project/scripts/Global.gd` | Autoload: input setup, scene transitions, game state |
| `godot_project/scripts/characters/CharacterBase.gd` | Base class: physics, state machine, health, damage |
| `godot_project/scripts/characters/Hitbox.gd` | Area2D that deals damage on overlap |
| `godot_project/scripts/characters/Hurtbox.gd` | Area2D that receives damage, forwards to parent |
| `godot_project/scripts/characters/Goku.gd` | Kamehameha, SSJ burst |
| `godot_project/scripts/characters/Naruto.gd` | Rasengan, Shadow Clone |
| `godot_project/scripts/characters/Luffy.gd` | Gum-Gum Pistol, Gear Second |
| `godot_project/scripts/characters/Conan.gd` | Stun gun, Soccer kick |
| `godot_project/scripts/characters/Doraemon.gd` | Anywhere Door, Bamboo Copter |
| `godot_project/scripts/characters/Sakura.gd` | Heal, Cherry Blossom Impact |
| `godot_project/scripts/game/GameManager.gd` | Round logic, win conditions, mode switching |
| `godot_project/scripts/game/AIController.gd` | AI state machine for 2v2 vs AI mode |
| `godot_project/scripts/networking/NetworkManager.gd` | Autoload: ENet host/join, LAN discovery, peer events |
| `godot_project/scripts/networking/RollbackManager.gd` | Input buffer, predict, rollback, sync |
| `godot_project/scripts/networking/RelayClient.gd` | WebSocket relay connection for internet play |
| `godot_project/scripts/ui/HUD.gd` | HP bars, special meter, timer, round indicator |
| `godot_project/scenes/MainMenu.tscn` | Menu: Local/LAN/Internet/Settings |
| `godot_project/scenes/CharacterSelect.tscn` | Character grid, player confirm |
| `godot_project/scenes/LobbyRoom.tscn` | Room code, player ready, mode select |
| `godot_project/scenes/GameArena.tscn` | Main arena with HUD, players, background |
| `godot_project/scenes/ResultScreen.tscn` | Winner display, rematch/menu buttons |
| `relay_server/package.json` | Node.js project |
| `relay_server/server.js` | WebSocket relay: rooms, forwarding, heartbeat |

---

## Phase 1: Project Foundation

### Task 1: Initialize Godot Project Structure

**Files:**
- Create: `godot_project/project.godot`
- Create: `godot_project/scripts/Global.gd`

- [ ] **Step 1: Create all directories**

```bash
cd /Users/luannt/doiKhang
mkdir -p godot_project/{scenes,scripts/{characters,game,networking,ui},assets/{characters,backgrounds,sfx,ui}}
mkdir -p relay_server
```

- [ ] **Step 2: Create `godot_project/project.godot`**

```ini
; Engine configuration file.

[gd_project id="doikhang_anime"]

config/name="DoiKhang Anime"
config/version="0.1.0"
config/features=PackedStringArray("4.3", "Forward Plus")
run/main_scene="res://scenes/MainMenu.tscn"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[physics]

2d/default_gravity=980

[autoload]

Global="*res://scripts/Global.gd"
NetworkManager="*res://scripts/networking/NetworkManager.gd"
```

- [ ] **Step 3: Create `godot_project/scripts/Global.gd`**

```gdscript
extends Node

# Game state shared across scenes
var selected_characters: Array[String] = ["Goku", "Naruto"]
var game_mode: String = "1v1"  # "1v1", "2v2_pvp", "2v2_ai"
var is_network_game: bool = false
var local_player_id: int = 1  # 1 or 2

const CHARACTER_COLORS: Dictionary = {
    "Goku": Color(1.0, 0.6, 0.1),
    "Naruto": Color(1.0, 0.7, 0.0),
    "Luffy": Color(0.9, 0.2, 0.2),
    "Conan": Color(0.2, 0.4, 0.9),
    "Doraemon": Color(0.1, 0.7, 0.9),
    "Sakura": Color(0.95, 0.5, 0.7),
}

const CHARACTER_NAMES: Array[String] = ["Goku", "Naruto", "Luffy", "Conan", "Doraemon", "Sakura"]

func _ready() -> void:
    _setup_input_map()

func _setup_input_map() -> void:
    var actions := {
        "p1_left": KEY_A, "p1_right": KEY_D,
        "p1_jump": KEY_W, "p1_crouch": KEY_S,
        "p1_attack": KEY_J, "p1_special": KEY_K,
        "p1_ultimate": KEY_L, "p1_block": KEY_SHIFT,
        "p2_left": KEY_LEFT, "p2_right": KEY_RIGHT,
        "p2_jump": KEY_UP, "p2_crouch": KEY_DOWN,
        "p2_attack": KEY_KP_1, "p2_special": KEY_KP_2,
        "p2_ultimate": KEY_KP_3, "p2_block": KEY_KP_0,
    }
    for action_name in actions:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
            var event := InputEventKey.new()
            event.physical_keycode = actions[action_name]
            InputMap.action_add_event(action_name, event)

func go_to_scene(path: String) -> void:
    get_tree().change_scene_to_file(path)

func get_input_bitmask(prefix: String) -> int:
    var bits := 0
    if Input.is_action_pressed(prefix + "left"):    bits |= 1
    if Input.is_action_pressed(prefix + "right"):   bits |= 2
    if Input.is_action_just_pressed(prefix + "jump"):    bits |= 4
    if Input.is_action_pressed(prefix + "crouch"):  bits |= 8
    if Input.is_action_just_pressed(prefix + "attack"):  bits |= 16
    if Input.is_action_just_pressed(prefix + "special"): bits |= 32
    if Input.is_action_just_pressed(prefix + "ultimate"):bits |= 64
    if Input.is_action_pressed(prefix + "block"):   bits |= 128
    return bits
```

- [ ] **Step 4: Commit**

```bash
cd /Users/luannt/doiKhang
git init
git add godot_project/project.godot godot_project/scripts/Global.gd
git commit -m "feat: initialize Godot project structure"
```

---

### Task 2: CharacterBase — Physics & State Machine

**Files:**
- Create: `godot_project/scripts/characters/CharacterBase.gd`

- [ ] **Step 1: Create `godot_project/scripts/characters/CharacterBase.gd`**

```gdscript
extends CharacterBody2D
class_name CharacterBase

signal health_changed(new_hp: float, max_hp: float)
signal special_changed(new_sp: float)
signal died
signal hit_landed(target: CharacterBase, damage: float)

const GRAVITY := 980.0
const JUMP_VELOCITY := -480.0
const MOVE_SPEED := 220.0
const FLOOR_Y := 580.0

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
var combo_count: int = 0
var last_hit_time: float = 0.0

enum State {
    IDLE, WALK, JUMP, CROUCH,
    ATTACK, SPECIAL, ULTIMATE,
    HURT, DEAD, BLOCK
}
var state: State = State.IDLE
var state_timer: float = 0.0

# Visual node (ColorRect placeholder)
@onready var body_rect: ColorRect = $BodyRect
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var hurtbox: Area2D = $Hurtbox

func setup(pid: int, prefix: String, local: bool) -> void:
    player_id = pid
    input_prefix = prefix
    is_local = local
    health = max_health
    special = 0.0
    if body_rect:
        body_rect.color = Global.CHARACTER_COLORS.get(char_name, Color.WHITE)

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    _apply_gravity(delta)
    state_timer -= delta
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
    if opponent and state not in [State.ATTACK, State.SPECIAL, State.ULTIMATE, State.HURT]:
        var diff := opponent.global_position.x - global_position.x
        if diff > 5.0:
            facing_right = true
            scale.x = 1.0
        elif diff < -5.0:
            facing_right = false
            scale.x = -1.0

func _process_state(delta: float) -> void:
    match state:
        State.IDLE:    _state_idle(delta)
        State.WALK:    _state_walk(delta)
        State.JUMP:    _state_jump(delta)
        State.CROUCH:  _state_crouch(delta)
        State.ATTACK:  _state_attack(delta)
        State.SPECIAL: _state_special(delta)
        State.ULTIMATE:_state_ultimate(delta)
        State.HURT:    _state_hurt(delta)
        State.BLOCK:   _state_block(delta)

func _get_input() -> int:
    if is_local:
        return Global.get_input_bitmask(input_prefix)
    return 0  # Overridden by network/AI

func _state_idle(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0, MOVE_SPEED * 8 * delta)
    var input := _get_input()
    _check_combat_input(input)
    if input & 1: _set_state(State.WALK)
    elif input & 2: _set_state(State.WALK)
    elif (input & 4) and is_on_floor(): _jump()
    elif input & 8: _set_state(State.CROUCH)
    elif input & 128: _set_state(State.BLOCK)

func _state_walk(delta: float) -> void:
    var input := _get_input()
    _check_combat_input(input)
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
    if input & 1: velocity.x = -MOVE_SPEED * 0.8
    elif input & 2: velocity.x = MOVE_SPEED * 0.8
    _check_combat_input(input)
    if is_on_floor():
        _set_state(State.IDLE)

func _state_crouch(_delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0, MOVE_SPEED * 12 * _delta)
    var input := _get_input()
    if not (input & 8):
        _set_state(State.IDLE)
    _check_combat_input(input)

func _state_attack(_delta: float) -> void:
    if state_timer <= 0.0:
        attack_hitbox.monitoring = false
        _set_state(State.IDLE)

func _state_special(_delta: float) -> void:
    if state_timer <= 0.0:
        _set_state(State.IDLE)

func _state_ultimate(_delta: float) -> void:
    if state_timer <= 0.0:
        _set_state(State.IDLE)

func _state_hurt(_delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0, 400.0 * _delta)
    if state_timer <= 0.0:
        _set_state(State.IDLE)

func _state_block(_delta: float) -> void:
    velocity.x = 0.0
    var input := _get_input()
    if not (input & 128):
        _set_state(State.IDLE)

func _check_combat_input(input: int) -> void:
    if input & 16: _do_attack()
    elif input & 32 and special >= 30.0: _do_special()
    elif input & 64 and special >= 80.0: _do_ultimate()

func _jump() -> void:
    velocity.y = JUMP_VELOCITY
    _set_state(State.JUMP)

func _do_attack() -> void:
    _set_state(State.ATTACK)
    state_timer = 0.3
    attack_hitbox.monitoring = true
    velocity.x += (1.0 if facing_right else -1.0) * 100.0
    get_tree().create_timer(0.15).timeout.connect(func(): attack_hitbox.monitoring = false)

func _do_special() -> void:
    # Override in subclass
    pass

func _do_ultimate() -> void:
    # Override in subclass
    pass

func _set_state(new_state: State) -> void:
    state = new_state
    state_timer = 0.0

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
    if is_dead:
        return
    if state == State.BLOCK:
        amount *= 0.15
        velocity += knockback * 0.3
    else:
        health = max(0.0, health - amount)
        velocity += knockback
        if state not in [State.ATTACK, State.SPECIAL, State.ULTIMATE]:
            _set_state(State.HURT)
            state_timer = 0.35
    health_changed.emit(health, max_health)
    combo_count += 1
    last_hit_time = Time.get_ticks_msec() / 1000.0
    if health <= 0.0:
        _die()

func add_special(amount: float) -> void:
    special = min(max_special, special + amount)
    special_changed.emit(special)

func _die() -> void:
    is_dead = true
    state = State.DEAD
    velocity = Vector2.ZERO
    died.emit()
```

- [ ] **Step 2: Verify file was created**

```bash
ls -la /Users/luannt/doiKhang/godot_project/scripts/characters/CharacterBase.gd
```
Expected: file exists, ~160 lines.

- [ ] **Step 3: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/characters/CharacterBase.gd
git commit -m "feat: add CharacterBase with state machine and physics"
```

---

### Task 3: Hitbox / Hurtbox System

**Files:**
- Create: `godot_project/scripts/characters/Hitbox.gd`
- Create: `godot_project/scripts/characters/Hurtbox.gd`

- [ ] **Step 1: Create `godot_project/scripts/characters/Hitbox.gd`**

```gdscript
extends Area2D
class_name Hitbox

@export var damage: float = 15.0
@export var knockback_force: float = 300.0

var owner_character: CharacterBase = null
var already_hit: Array[CharacterBase] = []

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    monitoring = false

func reset() -> void:
    already_hit.clear()

func _on_area_entered(area: Area2D) -> void:
    if area is Hurtbox:
        var target: CharacterBase = area.owner_character
        if target == null or target == owner_character:
            return
        if target in already_hit:
            return
        already_hit.append(target)
        var dir := sign(target.global_position.x - owner_character.global_position.x)
        var kb := Vector2(dir * knockback_force, -100.0)
        target.take_damage(damage, kb)
        owner_character.add_special(8.0)
        owner_character.hit_landed.emit(target, damage)
```

- [ ] **Step 2: Create `godot_project/scripts/characters/Hurtbox.gd`**

```gdscript
extends Area2D
class_name Hurtbox

var owner_character: CharacterBase = null
```

- [ ] **Step 3: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/characters/Hitbox.gd godot_project/scripts/characters/Hurtbox.gd
git commit -m "feat: add Hitbox and Hurtbox area2D nodes"
```

---

## Phase 2: Characters

### Task 4: Goku Character

**Files:**
- Create: `godot_project/scripts/characters/Goku.gd`

- [ ] **Step 1: Create `godot_project/scripts/characters/Goku.gd`**

```gdscript
extends CharacterBase
class_name Goku

const KAMEHAMEHA_DAMAGE := 35.0
const SSJ_DURATION := 5.0

var ssj_active: bool = false
var ssj_timer: float = 0.0
var ki_charge_rate: float = 3.0  # extra special per second when crouching

func _ready() -> void:
    char_name = "Goku"
    max_health = 110.0
    health = max_health

func _physics_process(delta: float) -> void:
    if ssj_active:
        ssj_timer -= delta
        if ssj_timer <= 0.0:
            ssj_active = false
            if body_rect:
                body_rect.color = Global.CHARACTER_COLORS["Goku"]
    super(delta)

func _state_crouch(delta: float) -> void:
    super(delta)
    add_special(ki_charge_rate * delta)

func _do_special() -> void:
    if special < 30.0:
        return
    special -= 30.0
    special_changed.emit(special)
    _set_state(State.SPECIAL)
    state_timer = 0.6
    # Fire Kamehameha projectile
    _fire_kamehameha()

func _fire_kamehameha() -> void:
    var projectile := _create_projectile(
        Color(0.3, 0.5, 1.0),
        Vector2(1.0 if facing_right else -1.0, 0.0) * 600.0,
        KAMEHAMEHA_DAMAGE,
        Vector2(80, 20)
    )
    get_parent().add_child(projectile)
    projectile.global_position = global_position + Vector2((1.0 if facing_right else -1.0) * 60.0, -20.0)

func _do_ultimate() -> void:
    if special < 80.0:
        return
    special -= 80.0
    special_changed.emit(special)
    ssj_active = true
    ssj_timer = SSJ_DURATION
    if body_rect:
        body_rect.color = Color(1.0, 1.0, 0.0)  # Golden SSJ
    _set_state(State.ULTIMATE)
    state_timer = 1.0

func _create_projectile(color: Color, vel: Vector2, dmg: float, size: Vector2) -> CharacterBody2D:
    var proj := CharacterBody2D.new()
    var rect := ColorRect.new()
    rect.color = color
    rect.size = size
    rect.position = -size / 2.0
    proj.add_child(rect)
    var col := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    col.shape = shape
    proj.add_child(col)
    var hitbox := Hitbox.new()
    hitbox.damage = dmg
    hitbox.owner_character = self
    hitbox.knockback_force = 200.0
    var hitbox_col := CollisionShape2D.new()
    var hitbox_shape := RectangleShape2D.new()
    hitbox_shape.size = size
    hitbox_col.shape = hitbox_shape
    hitbox.add_child(hitbox_col)
    proj.add_child(hitbox)
    hitbox.monitoring = true
    # Script to move and despawn
    var script_text := """
extends CharacterBody2D
var speed: Vector2 = Vector2.ZERO
func _physics_process(delta):
    velocity = speed
    move_and_slide()
    if position.x < -100 or position.x > 1400:
        queue_free()
"""
    var script := GDScript.new()
    script.source_code = script_text
    proj.set_script(script)
    proj.set("speed", vel)
    return proj
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/characters/Goku.gd
git commit -m "feat: add Goku with Kamehameha and Super Saiyan"
```

---

### Task 5: Naruto Character

**Files:**
- Create: `godot_project/scripts/characters/Naruto.gd`

- [ ] **Step 1: Create `godot_project/scripts/characters/Naruto.gd`**

```gdscript
extends CharacterBase
class_name Naruto

const RASENGAN_DAMAGE := 40.0
const CLONE_COUNT := 2
const CLONE_DURATION := 5.0

var clones: Array[Node] = []
var clone_timer: float = 0.0

func _ready() -> void:
    char_name = "Naruto"
    max_health = 100.0
    health = max_health

func _physics_process(delta: float) -> void:
    if clones.size() > 0:
        clone_timer -= delta
        if clone_timer <= 0.0:
            _destroy_clones()
    super(delta)

func _do_special() -> void:
    if special < 30.0:
        return
    special -= 30.0
    special_changed.emit(special)
    _set_state(State.SPECIAL)
    state_timer = 0.5
    # Dash forward + Rasengan hit
    velocity.x = (1.0 if facing_right else -1.0) * 400.0
    if attack_hitbox:
        attack_hitbox.damage = RASENGAN_DAMAGE
        attack_hitbox.monitoring = true
        get_tree().create_timer(0.25).timeout.connect(func():
            attack_hitbox.monitoring = false
            if attack_hitbox:
                attack_hitbox.damage = 15.0
        )

func _do_ultimate() -> void:
    if special < 80.0:
        return
    special -= 80.0
    special_changed.emit(special)
    _set_state(State.ULTIMATE)
    state_timer = 1.0
    _destroy_clones()
    _spawn_clones()

func _spawn_clones() -> void:
    clone_timer = CLONE_DURATION
    for i in range(CLONE_COUNT):
        var clone := _make_clone(i)
        get_parent().add_child(clone)
        clones.append(clone)

func _make_clone(index: int) -> Node2D:
    var clone := Node2D.new()
    var rect := ColorRect.new()
    rect.color = Color(Global.CHARACTER_COLORS["Naruto"], 0.6)
    rect.size = Vector2(40, 80)
    rect.position = Vector2(-20, -80)
    clone.add_child(rect)
    clone.global_position = global_position + Vector2((index + 1) * 60.0 * (1.0 if facing_right else -1.0), 0.0)
    # Simple clone AI: mirror owner movement
    var script_text := """
extends Node2D
var owner_char: CharacterBase = null
func _physics_process(delta):
    if owner_char == null or not is_instance_valid(owner_char):
        return
    global_position = owner_char.global_position + Vector2(offset_x, 0)
var offset_x: float = 60.0
"""
    var script := GDScript.new()
    script.source_code = script_text
    clone.set_script(script)
    clone.set("owner_char", self)
    clone.set("offset_x", (index + 1) * 65.0 * (1.0 if facing_right else -1.0))
    return clone

func _destroy_clones() -> void:
    for c in clones:
        if is_instance_valid(c):
            c.queue_free()
    clones.clear()
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/characters/Naruto.gd
git commit -m "feat: add Naruto with Rasengan and Shadow Clone"
```

---

### Task 6: Luffy, Conan, Doraemon, Sakura

**Files:**
- Create: `godot_project/scripts/characters/Luffy.gd`
- Create: `godot_project/scripts/characters/Conan.gd`
- Create: `godot_project/scripts/characters/Doraemon.gd`
- Create: `godot_project/scripts/characters/Sakura.gd`

- [ ] **Step 1: Create `godot_project/scripts/characters/Luffy.gd`**

```gdscript
extends CharacterBase
class_name Luffy

const PISTOL_DAMAGE := 20.0
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
            if body_rect:
                body_rect.color = Global.CHARACTER_COLORS["Luffy"]
    super(delta)

func _do_special() -> void:
    if special < 30.0:
        return
    special -= 30.0
    special_changed.emit(special)
    _set_state(State.SPECIAL)
    state_timer = 0.4
    # Long range extending punch — teleport-style
    var reach := Vector2((1.0 if facing_right else -1.0) * 250.0, 0.0)
    var target_pos := global_position + reach
    if opponent:
        var dist := opponent.global_position.distance_to(global_position)
        if dist < 300.0:
            opponent.take_damage(PISTOL_DAMAGE, Vector2((1.0 if facing_right else -1.0) * 350.0, -80.0))
            add_special(5.0)

func _do_ultimate() -> void:
    if special < 80.0:
        return
    special -= 80.0
    special_changed.emit(special)
    gear2_active = true
    gear2_timer = GEAR2_DURATION
    if body_rect:
        body_rect.color = Color(1.0, 0.4, 0.4)
    _set_state(State.ULTIMATE)
    state_timer = 0.8
```

- [ ] **Step 2: Create `godot_project/scripts/characters/Conan.gd`**

```gdscript
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
    # Stun gun: if opponent close, stun them
    if opponent and global_position.distance_to(opponent.global_position) < 180.0:
        opponent.state = CharacterBase.State.HURT
        opponent.state_timer = STUN_DURATION
        opponent.velocity.x = 0.0
        add_special(10.0)

func _do_ultimate() -> void:
    if special < 80.0:
        return
    special -= 80.0
    special_changed.emit(special)
    _set_state(State.ULTIMATE)
    state_timer = 1.2
    # Soccer ball combo: 5 rapid hits
    var hits_done := 0
    for i in range(SOCCER_HITS):
        get_tree().create_timer(i * 0.2).timeout.connect(func():
            if opponent and is_instance_valid(opponent) and not opponent.is_dead:
                var dir := sign(opponent.global_position.x - global_position.x)
                opponent.take_damage(
                    SOCCER_DAMAGE_PER_HIT,
                    Vector2(dir * 200.0, -60.0)
                )
        )
```

- [ ] **Step 3: Create `godot_project/scripts/characters/Doraemon.gd`**

```gdscript
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
    # Anywhere Door: teleport to mouse/opponent side
    if opponent:
        var target_x := opponent.global_position.x + (1.0 if not facing_right else -1.0) * 80.0
        global_position.x = clamp(target_x, 80.0, 1200.0)

func _do_ultimate() -> void:
    if special < 80.0:
        return
    special -= 80.0
    special_changed.emit(special)
    copter_active = true
    copter_timer = COPTER_DURATION
    _set_state(State.ULTIMATE)
    state_timer = COPTER_DURATION
    # Spin in place — large hitbox active
    if attack_hitbox:
        attack_hitbox.damage = 25.0
        attack_hitbox.monitoring = true
        get_tree().create_timer(COPTER_DURATION).timeout.connect(func():
            if attack_hitbox:
                attack_hitbox.monitoring = false
                attack_hitbox.damage = 15.0
        )
```

- [ ] **Step 4: Create `godot_project/scripts/characters/Sakura.gd`**

```gdscript
extends CharacterBase
class_name Sakura

const HEAL_AMOUNT := 15.0
const IMPACT_DAMAGE := 55.0
const REGEN_RATE := 5.0  # HP per second when not hit

var time_since_last_hit: float = 999.0
var regen_active: bool = false

func _ready() -> void:
    char_name = "Sakura"
    max_health = 100.0
    health = max_health

func _physics_process(delta: float) -> void:
    time_since_last_hit += delta
    if time_since_last_hit > 3.0 and not is_dead:
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
    if special < 80.0:
        return
    special -= 80.0
    special_changed.emit(special)
    _set_state(State.ULTIMATE)
    state_timer = 0.6
    # Ground slam AoE
    velocity.y = 200.0
    if opponent and global_position.distance_to(opponent.global_position) < 250.0:
        opponent.take_damage(
            IMPACT_DAMAGE,
            Vector2(sign(opponent.global_position.x - global_position.x) * 400.0, -200.0)
        )
    add_special(20.0)
```

- [ ] **Step 5: Commit all characters**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/characters/
git commit -m "feat: add Luffy, Conan, Doraemon, Sakura characters"
```

---

## Phase 3: Game Logic

### Task 7: GameManager — Rounds & Win Conditions

**Files:**
- Create: `godot_project/scripts/game/GameManager.gd`

- [ ] **Step 1: Create `godot_project/scripts/game/GameManager.gd`**

```gdscript
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
        p.health = p.max_health
        p.special = 0.0
        p.is_dead = false
        p.state = CharacterBase.State.IDLE
        p.health_changed.emit(p.health, p.max_health)
    _reset_positions()
    round_started.emit(current_round)

func _reset_positions() -> void:
    if players.size() >= 2:
        players[0].global_position = Vector2(300, 500)
        players[1].global_position = Vector2(980, 500)
        players[0].facing_right = true
        players[0].scale.x = 1.0
        players[1].facing_right = false
        players[1].scale.x = -1.0

func _process(delta: float) -> void:
    if not round_active:
        return
    round_timer -= delta
    timer_updated.emit(round_timer)
    if round_timer <= 0.0:
        _end_round_timeout()

func _on_player_died(player: CharacterBase) -> void:
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
    if round_wins.get(winner_id, 0) >= 2:
        await get_tree().create_timer(1.5).timeout
        match_ended.emit(winner_id)
    elif current_round < MAX_ROUNDS:
        await get_tree().create_timer(2.0).timeout
        current_round += 1
        _start_round()
    else:
        var final_winner := _get_most_wins()
        await get_tree().create_timer(1.5).timeout
        match_ended.emit(final_winner)

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
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/game/GameManager.gd
git commit -m "feat: add GameManager with round logic and win conditions"
```

---

### Task 8: HUD

**Files:**
- Create: `godot_project/scripts/ui/HUD.gd`

- [ ] **Step 1: Create `godot_project/scripts/ui/HUD.gd`**

```gdscript
extends CanvasLayer
class_name HUD

@onready var p1_hp_bar: ProgressBar = $P1Side/HPBar
@onready var p1_sp_bar: ProgressBar = $P1Side/SPBar
@onready var p1_name: Label = $P1Side/CharName
@onready var p2_hp_bar: ProgressBar = $P2Side/HPBar
@onready var p2_sp_bar: ProgressBar = $P2Side/SPBar
@onready var p2_name: Label = $P2Side/CharName
@onready var timer_label: Label = $CenterPanel/TimerLabel
@onready var round_label: Label = $CenterPanel/RoundLabel
@onready var announce_label: Label = $CenterPanel/AnnounceLabel
@onready var p1_wins: HBoxContainer = $P1Side/WinDots
@onready var p2_wins: HBoxContainer = $P2Side/WinDots

func setup_players(p1: CharacterBase, p2: CharacterBase) -> void:
    p1_name.text = p1.char_name
    p2_name.text = p2.char_name
    p1_hp_bar.max_value = p1.max_health
    p1_hp_bar.value = p1.health
    p1_sp_bar.max_value = p1.max_special
    p1_sp_bar.value = 0.0
    p2_hp_bar.max_value = p2.max_health
    p2_hp_bar.value = p2.health
    p2_sp_bar.max_value = p2.max_special
    p2_sp_bar.value = 0.0
    p1.health_changed.connect(func(hp, _max): p1_hp_bar.value = hp)
    p1.special_changed.connect(func(sp): p1_sp_bar.value = sp)
    p2.health_changed.connect(func(hp, _max): p2_hp_bar.value = hp)
    p2.special_changed.connect(func(sp): p2_sp_bar.value = sp)

func update_timer(seconds: float) -> void:
    timer_label.text = "%02d" % int(ceil(seconds))
    if seconds <= 10.0:
        timer_label.modulate = Color.RED
    else:
        timer_label.modulate = Color.WHITE

func show_round(num: int) -> void:
    round_label.text = "ROUND %d" % num
    announce("ROUND %d" % num)

func announce(text: String, duration: float = 1.5) -> void:
    announce_label.text = text
    announce_label.visible = true
    get_tree().create_timer(duration).timeout.connect(func():
        if is_instance_valid(announce_label):
            announce_label.visible = false
    )

func update_wins(p1_wins_count: int, p2_wins_count: int) -> void:
    for i in range(p1_wins.get_child_count()):
        var dot := p1_wins.get_child(i)
        dot.modulate = Color.YELLOW if i < p1_wins_count else Color.DARK_GRAY
    for i in range(p2_wins.get_child_count()):
        var dot := p2_wins.get_child(i)
        dot.modulate = Color.YELLOW if i < p2_wins_count else Color.DARK_GRAY
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/ui/HUD.gd
git commit -m "feat: add HUD script for HP bars, timer, round display"
```

---

### Task 9: AI Controller

**Files:**
- Create: `godot_project/scripts/game/AIController.gd`

- [ ] **Step 1: Create `godot_project/scripts/game/AIController.gd`**

```gdscript
extends Node
class_name AIController

enum Difficulty { EASY, MEDIUM, HARD }
enum AIState { IDLE, APPROACH, ATTACK, RETREAT, BLOCK }

@export var difficulty: Difficulty = Difficulty.MEDIUM

var controlled_char: CharacterBase = null
var ai_state: AIState = AIState.IDLE
var reaction_delay: float = 0.2
var action_timer: float = 0.0

const REACTION_TIMES := {
    Difficulty.EASY: 0.5,
    Difficulty.MEDIUM: 0.2,
    Difficulty.HARD: 0.08,
}
const ATTACK_RANGE := 180.0
const APPROACH_RANGE := 350.0

func _ready() -> void:
    reaction_delay = REACTION_TIMES[difficulty]

func setup(character: CharacterBase) -> void:
    controlled_char = character
    controlled_char.is_local = false

func _process(delta: float) -> void:
    if controlled_char == null or controlled_char.is_dead:
        return
    action_timer -= delta
    if action_timer > 0.0:
        return
    action_timer = reaction_delay + randf() * 0.1
    _decide_action()

func _decide_action() -> void:
    var opp := controlled_char.opponent
    if opp == null or opp.is_dead:
        return
    var dist := controlled_char.global_position.distance_to(opp.global_position)
    var is_facing := _is_facing_opponent()

    # Decide AI state
    if dist < ATTACK_RANGE and is_facing:
        ai_state = AIState.ATTACK
    elif dist < APPROACH_RANGE:
        ai_state = AIState.APPROACH
    else:
        ai_state = AIState.APPROACH

    _execute_action(dist, opp)

func _execute_action(dist: float, opp: CharacterBase) -> void:
    match ai_state:
        AIState.APPROACH:
            var dir := sign(opp.global_position.x - controlled_char.global_position.x)
            controlled_char.velocity.x = dir * CharacterBase.MOVE_SPEED * 0.9
            controlled_char.state = CharacterBase.State.WALK

        AIState.ATTACK:
            # Choose attack
            var roll := randf()
            if controlled_char.special >= 80.0 and difficulty == Difficulty.HARD and roll < 0.3:
                controlled_char._do_ultimate()
            elif controlled_char.special >= 30.0 and roll < 0.4:
                controlled_char._do_special()
            else:
                controlled_char._do_attack()

        AIState.RETREAT:
            var dir := -sign(opp.global_position.x - controlled_char.global_position.x)
            controlled_char.velocity.x = dir * CharacterBase.MOVE_SPEED

func _is_facing_opponent() -> bool:
    if controlled_char.opponent == null:
        return false
    var diff := controlled_char.opponent.global_position.x - controlled_char.global_position.x
    return (diff > 0) == controlled_char.facing_right
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/game/AIController.gd
git commit -m "feat: add AIController with easy/medium/hard difficulty"
```

---

## Phase 4: Scenes

### Task 10: GameArena Scene

**Files:**
- Create: `godot_project/scenes/GameArena.tscn`

- [ ] **Step 1: Create `godot_project/scenes/GameArena.tscn`**

```gdscript
# Create via script: godot_project/scripts/game/ArenaSetup.gd
# This script builds the arena scene programmatically

# Instead, create the file directly:
```

Create `godot_project/scenes/GameArena.tscn`:

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/game/ArenaScene.gd" id="1"]
[ext_resource type="Script" path="res://scripts/ui/HUD.gd" id="2"]

[node name="GameArena" type="Node2D"]
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
color = Color(0.1, 0.15, 0.35, 1)
size = Vector2(1280, 720)
position = Vector2(0, 0)

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(640, 620)

[node name="GroundShape" type="CollisionShape2D" parent="Ground"]

[node name="GroundRect" type="ColorRect" parent="Ground"]
color = Color(0.3, 0.2, 0.1, 1)
size = Vector2(1280, 100)
position = Vector2(-640, 0)

[node name="Players" type="Node2D" parent="."]

[node name="HUD" type="CanvasLayer" parent="."]
script = ExtResource("2")

[node name="P1Side" type="HBoxContainer" parent="HUD"]
position = Vector2(20, 20)
size = Vector2(500, 60)

[node name="CharName" type="Label" parent="HUD/P1Side"]
text = "Player 1"

[node name="HPBar" type="ProgressBar" parent="HUD/P1Side"]
custom_minimum_size = Vector2(300, 24)
max_value = 100

[node name="SPBar" type="ProgressBar" parent="HUD/P1Side"]
custom_minimum_size = Vector2(300, 12)
max_value = 100

[node name="WinDots" type="HBoxContainer" parent="HUD/P1Side"]

[node name="Dot1" type="ColorRect" parent="HUD/P1Side/WinDots"]
custom_minimum_size = Vector2(16, 16)
color = Color(0.3, 0.3, 0.3, 1)

[node name="Dot2" type="ColorRect" parent="HUD/P1Side/WinDots"]
custom_minimum_size = Vector2(16, 16)
color = Color(0.3, 0.3, 0.3, 1)

[node name="CenterPanel" type="VBoxContainer" parent="HUD"]
position = Vector2(540, 10)
size = Vector2(200, 80)

[node name="TimerLabel" type="Label" parent="HUD/CenterPanel"]
text = "90"
horizontal_alignment = 1

[node name="RoundLabel" type="Label" parent="HUD/CenterPanel"]
text = "ROUND 1"
horizontal_alignment = 1

[node name="AnnounceLabel" type="Label" parent="HUD/CenterPanel"]
text = ""
horizontal_alignment = 1
visible = false

[node name="P2Side" type="HBoxContainer" parent="HUD"]
position = Vector2(760, 20)
size = Vector2(500, 60)

[node name="CharName" type="Label" parent="HUD/P2Side"]
text = "Player 2"

[node name="HPBar" type="ProgressBar" parent="HUD/P2Side"]
custom_minimum_size = Vector2(300, 24)
max_value = 100

[node name="SPBar" type="ProgressBar" parent="HUD/P2Side"]
custom_minimum_size = Vector2(300, 12)
max_value = 100

[node name="WinDots" type="HBoxContainer" parent="HUD/P2Side"]

[node name="Dot1" type="ColorRect" parent="HUD/P2Side/WinDots"]
custom_minimum_size = Vector2(16, 16)
color = Color(0.3, 0.3, 0.3, 1)

[node name="Dot2" type="ColorRect" parent="HUD/P2Side/WinDots"]
custom_minimum_size = Vector2(16, 16)
color = Color(0.3, 0.3, 0.3, 1)
```

- [ ] **Step 2: Create `godot_project/scripts/game/ArenaScene.gd`**

```gdscript
extends Node2D

@onready var players_node: Node2D = $Players
@onready var hud: HUD = $HUD

var game_manager: GameManager
var player_chars: Array[CharacterBase] = []

func _ready() -> void:
    game_manager = GameManager.new()
    add_child(game_manager)
    game_manager.round_started.connect(_on_round_started)
    game_manager.round_ended.connect(_on_round_ended)
    game_manager.match_ended.connect(_on_match_ended)
    game_manager.timer_updated.connect(hud.update_timer)
    _spawn_players()

func _spawn_players() -> void:
    var char_names := Global.selected_characters
    var chars_to_spawn := [
        char_names[0] if char_names.size() > 0 else "Goku",
        char_names[1] if char_names.size() > 1 else "Naruto",
    ]
    for i in range(2):
        var char_node := _create_character(chars_to_spawn[i], i + 1)
        players_node.add_child(char_node)
        player_chars.append(char_node)
    player_chars[0].opponent = player_chars[1]
    player_chars[1].opponent = player_chars[0]
    hud.setup_players(player_chars[0], player_chars[1])
    game_manager.start_match(player_chars)
    if Global.game_mode == "2v2_ai":
        _setup_ai_for_player(player_chars[1])

func _create_character(char_name: String, pid: int) -> CharacterBase:
    var char_node: CharacterBase
    match char_name:
        "Goku":     char_node = Goku.new()
        "Naruto":   char_node = Naruto.new()
        "Luffy":    char_node = Luffy.new()
        "Conan":    char_node = Conan.new()
        "Doraemon": char_node = Doraemon.new()
        "Sakura":   char_node = Sakura.new()
        _:          char_node = Goku.new()

    # Add visual body rect
    var body_rect := ColorRect.new()
    body_rect.name = "BodyRect"
    body_rect.size = Vector2(50, 90)
    body_rect.position = Vector2(-25, -90)
    body_rect.color = Global.CHARACTER_COLORS.get(char_name, Color.WHITE)
    char_node.add_child(body_rect)

    # Add collision shape
    var col := CollisionShape2D.new()
    var shape := CapsuleShape2D.new()
    shape.radius = 25.0
    shape.height = 80.0
    col.shape = shape
    col.position = Vector2(0, -45)
    char_node.add_child(col)

    # Add attack hitbox
    var attack_hitbox := Hitbox.new()
    attack_hitbox.name = "AttackHitbox"
    attack_hitbox.damage = 15.0
    attack_hitbox.knockback_force = 280.0
    attack_hitbox.owner_character = char_node
    var atk_col := CollisionShape2D.new()
    var atk_shape := RectangleShape2D.new()
    atk_shape.size = Vector2(80, 50)
    atk_col.shape = atk_shape
    atk_col.position = Vector2(60, -40)
    attack_hitbox.add_child(atk_col)
    char_node.add_child(attack_hitbox)

    # Add hurtbox
    var hurtbox := Hurtbox.new()
    hurtbox.name = "Hurtbox"
    hurtbox.owner_character = char_node
    var hurt_col := CollisionShape2D.new()
    var hurt_shape := CapsuleShape2D.new()
    hurt_shape.radius = 28.0
    hurt_shape.height = 85.0
    hurt_col.shape = hurt_shape
    hurt_col.position = Vector2(0, -45)
    hurtbox.add_child(hurt_col)
    char_node.add_child(hurtbox)

    # Floor ground
    var floor_shape := StaticBody2D.new()
    var floor_col := CollisionShape2D.new()
    var floor_rect_shape := WorldBoundaryShape2D.new()
    floor_col.shape = floor_rect_shape
    floor_col.position = Vector2(0, 580)
    char_node.get_parent()

    char_node.setup(pid, "p%d_" % pid, not Global.is_network_game or NetworkManager.is_host)
    char_node.global_position = Vector2(300 if pid == 1 else 980, 500)
    return char_node

func _setup_ai_for_player(char_node: CharacterBase) -> void:
    var ai := AIController.new()
    ai.difficulty = AIController.Difficulty.MEDIUM
    add_child(ai)
    ai.setup(char_node)

func _on_round_started(round_num: int) -> void:
    hud.show_round(round_num)

func _on_round_ended(winner_id: int) -> void:
    var msg := "PLAYER %d WINS ROUND!" % winner_id if winner_id > 0 else "DRAW!"
    hud.announce(msg, 2.0)
    hud.update_wins(
        game_manager.round_wins.get(1, 0),
        game_manager.round_wins.get(2, 0)
    )

func _on_match_ended(winner_id: int) -> void:
    hud.announce("PLAYER %d WINS!" % winner_id, 3.0)
    await get_tree().create_timer(3.5).timeout
    Global.go_to_scene("res://scenes/ResultScreen.tscn")
```

- [ ] **Step 3: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scenes/GameArena.tscn godot_project/scripts/game/ArenaScene.gd
git commit -m "feat: add GameArena scene with player spawning and game manager"
```

---

### Task 11: MainMenu Scene

**Files:**
- Create: `godot_project/scenes/MainMenu.tscn`
- Create: `godot_project/scripts/ui/MainMenu.gd`

- [ ] **Step 1: Create `godot_project/scripts/ui/MainMenu.gd`**

```gdscript
extends Control

func _ready() -> void:
    $VBox/PlayLocalBtn.pressed.connect(_on_local)
    $VBox/PlayLANBtn.pressed.connect(_on_lan)
    $VBox/PlayInternetBtn.pressed.connect(_on_internet)
    $VBox/QuitBtn.pressed.connect(get_tree().quit)

func _on_local() -> void:
    Global.is_network_game = false
    Global.go_to_scene("res://scenes/CharacterSelect.tscn")

func _on_lan() -> void:
    Global.is_network_game = true
    NetworkManager.connection_type = "lan"
    Global.go_to_scene("res://scenes/LobbyRoom.tscn")

func _on_internet() -> void:
    Global.is_network_game = true
    NetworkManager.connection_type = "internet"
    Global.go_to_scene("res://scenes/LobbyRoom.tscn")
```

- [ ] **Step 2: Create `godot_project/scenes/MainMenu.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/MainMenu.gd" id="1"]

[node name="MainMenu" type="Control"]
script = ExtResource("1")
anchors_preset = 15

[node name="Background" type="ColorRect" parent="."]
color = Color(0.05, 0.05, 0.15, 1)
size = Vector2(1280, 720)

[node name="TitleLabel" type="Label" parent="."]
position = Vector2(340, 100)
size = Vector2(600, 80)
text = "DOIKHANG ANIME"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 64

[node name="VBox" type="VBoxContainer" parent="."]
position = Vector2(490, 240)
size = Vector2(300, 300)

[node name="PlayLocalBtn" type="Button" parent="VBox"]
text = "Play Local"
custom_minimum_size = Vector2(300, 55)

[node name="PlayLANBtn" type="Button" parent="VBox"]
text = "Play LAN"
custom_minimum_size = Vector2(300, 55)

[node name="PlayInternetBtn" type="Button" parent="VBox"]
text = "Play Internet"
custom_minimum_size = Vector2(300, 55)

[node name="QuitBtn" type="Button" parent="VBox"]
text = "Quit"
custom_minimum_size = Vector2(300, 55)
```

- [ ] **Step 3: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scenes/MainMenu.tscn godot_project/scripts/ui/MainMenu.gd
git commit -m "feat: add MainMenu scene with local/LAN/internet options"
```

---

### Task 12: CharacterSelect Scene

**Files:**
- Create: `godot_project/scenes/CharacterSelect.tscn`
- Create: `godot_project/scripts/ui/CharacterSelect.gd`

- [ ] **Step 1: Create `godot_project/scripts/ui/CharacterSelect.gd`**

```gdscript
extends Control

var p1_selected: String = ""
var p2_selected: String = ""
var both_confirmed: bool = false

@onready var p1_grid: GridContainer = $P1Panel/Grid
@onready var p2_grid: GridContainer = $P2Panel/Grid
@onready var p1_confirm: Button = $P1Panel/ConfirmBtn
@onready var p2_confirm: Button = $P2Panel/ConfirmBtn
@onready var start_btn: Button = $StartBtn
@onready var mode_option: OptionButton = $ModeOption

func _ready() -> void:
    _populate_grids()
    p1_confirm.pressed.connect(func(): _confirm_player(1))
    p2_confirm.pressed.connect(func(): _confirm_player(2))
    start_btn.pressed.connect(_start_game)
    start_btn.disabled = true
    for mode in ["1v1 PvP", "2v2 vs AI", "2v2 PvP"]:
        mode_option.add_item(mode)

func _populate_grids() -> void:
    for char_name in Global.CHARACTER_NAMES:
        var btn := Button.new()
        btn.text = char_name
        btn.custom_minimum_size = Vector2(100, 80)
        var p1_btn := btn.duplicate()
        p1_btn.pressed.connect(func(): _select(1, char_name))
        p1_grid.add_child(p1_btn)
        var p2_btn := btn.duplicate()
        p2_btn.pressed.connect(func(): _select(2, char_name))
        p2_grid.add_child(p2_btn)

func _select(player_id: int, char_name: String) -> void:
    if player_id == 1:
        p1_selected = char_name
    else:
        p2_selected = char_name

func _confirm_player(player_id: int) -> void:
    var sel := p1_selected if player_id == 1 else p2_selected
    if sel.is_empty():
        return
    if player_id == 1:
        $P1Panel/ConfirmedLabel.text = "✓ " + sel
    else:
        $P2Panel/ConfirmedLabel.text = "✓ " + sel
    _check_ready()

func _check_ready() -> void:
    if not p1_selected.is_empty() and not p2_selected.is_empty():
        start_btn.disabled = false

func _start_game() -> void:
    Global.selected_characters = [p1_selected, p2_selected]
    match mode_option.get_selected_id():
        0: Global.game_mode = "1v1"
        1: Global.game_mode = "2v2_ai"
        2: Global.game_mode = "2v2_pvp"
    if Global.is_network_game:
        Global.go_to_scene("res://scenes/LobbyRoom.tscn")
    else:
        Global.go_to_scene("res://scenes/GameArena.tscn")
```

- [ ] **Step 2: Create `godot_project/scenes/CharacterSelect.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/CharacterSelect.gd" id="1"]

[node name="CharacterSelect" type="Control"]
script = ExtResource("1")
anchors_preset = 15

[node name="Background" type="ColorRect" parent="."]
color = Color(0.05, 0.05, 0.2, 1)
size = Vector2(1280, 720)

[node name="Title" type="Label" parent="."]
position = Vector2(440, 20)
text = "SELECT YOUR FIGHTER"
theme_override_font_sizes/font_size = 36

[node name="P1Panel" type="VBoxContainer" parent="."]
position = Vector2(60, 80)
size = Vector2(500, 500)

[node name="P1Label" type="Label" parent="P1Panel"]
text = "PLAYER 1 (WASD + JKL)"
theme_override_font_sizes/font_size = 18

[node name="Grid" type="GridContainer" parent="P1Panel"]
columns = 3

[node name="ConfirmedLabel" type="Label" parent="P1Panel"]
text = "Not selected"

[node name="ConfirmBtn" type="Button" parent="P1Panel"]
text = "CONFIRM"
custom_minimum_size = Vector2(200, 45)

[node name="P2Panel" type="VBoxContainer" parent="."]
position = Vector2(720, 80)
size = Vector2(500, 500)

[node name="P2Label" type="Label" parent="P2Panel"]
text = "PLAYER 2 (Arrows + Numpad)"
theme_override_font_sizes/font_size = 18

[node name="Grid" type="GridContainer" parent="P2Panel"]
columns = 3

[node name="ConfirmedLabel" type="Label" parent="P2Panel"]
text = "Not selected"

[node name="ConfirmBtn" type="Button" parent="P2Panel"]
text = "CONFIRM"
custom_minimum_size = Vector2(200, 45)

[node name="ModeOption" type="OptionButton" parent="."]
position = Vector2(490, 620)
size = Vector2(300, 45)

[node name="StartBtn" type="Button" parent="."]
position = Vector2(540, 670)
text = "START FIGHT!"
custom_minimum_size = Vector2(200, 45)
disabled = true
```

- [ ] **Step 3: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scenes/CharacterSelect.tscn godot_project/scripts/ui/CharacterSelect.gd
git commit -m "feat: add CharacterSelect scene"
```

---

### Task 13: ResultScreen Scene

**Files:**
- Create: `godot_project/scenes/ResultScreen.tscn`
- Create: `godot_project/scripts/ui/ResultScreen.gd`

- [ ] **Step 1: Create `godot_project/scripts/ui/ResultScreen.gd`**

```gdscript
extends Control

@onready var winner_label: Label = $WinnerLabel
@onready var rematch_btn: Button = $Buttons/RematchBtn
@onready var menu_btn: Button = $Buttons/MenuBtn

func _ready() -> void:
    winner_label.text = "PLAYER %d WINS!" % Global.last_winner
    rematch_btn.pressed.connect(func(): Global.go_to_scene("res://scenes/GameArena.tscn"))
    menu_btn.pressed.connect(func(): Global.go_to_scene("res://scenes/MainMenu.tscn"))
```

Add `var last_winner: int = 1` to `Global.gd`.

- [ ] **Step 2: Create `godot_project/scenes/ResultScreen.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/ResultScreen.gd" id="1"]

[node name="ResultScreen" type="Control"]
script = ExtResource("1")
anchors_preset = 15

[node name="Background" type="ColorRect" parent="."]
color = Color(0.02, 0.02, 0.1, 1)
size = Vector2(1280, 720)

[node name="WinnerLabel" type="Label" parent="."]
position = Vector2(290, 250)
size = Vector2(700, 100)
text = "PLAYER 1 WINS!"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 72

[node name="Buttons" type="HBoxContainer" parent="."]
position = Vector2(390, 420)
size = Vector2(500, 60)

[node name="RematchBtn" type="Button" parent="Buttons"]
text = "REMATCH"
custom_minimum_size = Vector2(220, 55)

[node name="MenuBtn" type="Button" parent="Buttons"]
text = "MAIN MENU"
custom_minimum_size = Vector2(220, 55)
```

- [ ] **Step 3: Update Global.gd — add last_winner**

In `godot_project/scripts/Global.gd`, add after `var local_player_id`:
```gdscript
var last_winner: int = 1
```

And update `ArenaScene.gd`'s `_on_match_ended`:
```gdscript
func _on_match_ended(winner_id: int) -> void:
    Global.last_winner = winner_id
    hud.announce("PLAYER %d WINS!" % winner_id, 3.0)
    await get_tree().create_timer(3.5).timeout
    Global.go_to_scene("res://scenes/ResultScreen.tscn")
```

- [ ] **Step 4: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scenes/ResultScreen.tscn godot_project/scripts/ui/ResultScreen.gd godot_project/scripts/Global.gd godot_project/scripts/game/ArenaScene.gd
git commit -m "feat: add ResultScreen and wire match end to scene transition"
```

---

## Phase 5: Networking

### Task 14: NetworkManager (ENet Host/Client)

**Files:**
- Create: `godot_project/scripts/networking/NetworkManager.gd`

- [ ] **Step 1: Create `godot_project/scripts/networking/NetworkManager.gd`**

```gdscript
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed
signal server_disconnected

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var is_host: bool = false
var connection_type: String = "lan"  # "lan" or "internet"
var room_code: String = ""
var connected_peers: Array[int] = []

var relay_client: RelayClient = null

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT) -> Error:
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_server(port, MAX_PLAYERS)
    if err != OK:
        push_error("Failed to create server: " + error_string(err))
        return err
    multiplayer.multiplayer_peer = peer
    is_host = true
    connected_peers.clear()
    print("Server started on port %d" % port)
    return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_client(address, port)
    if err != OK:
        push_error("Failed to connect: " + error_string(err))
        return err
    multiplayer.multiplayer_peer = peer
    is_host = false
    print("Connecting to %s:%d" % [address, port])
    return OK

func disconnect_from_game() -> void:
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = null
    connected_peers.clear()
    is_host = false

func get_player_count() -> int:
    return connected_peers.size() + (1 if multiplayer.is_server() else 0)

# LAN discovery via UDP broadcast
var udp_server: UDPServer = null
var discovery_socket: PacketPeerUDP = null
var discovered_rooms: Array[Dictionary] = []

func start_lan_discovery_host() -> void:
    udp_server = UDPServer.new()
    udp_server.listen(7778)
    # Broadcast presence
    var broadcast := PacketPeerUDP.new()
    broadcast.set_broadcast_enabled(true)
    broadcast.set_dest_address("255.255.255.255", 7778)
    var data := JSON.stringify({"type": "host_announce", "port": DEFAULT_PORT, "name": "DoiKhang Room"})
    broadcast.put_packet(data.to_utf8_buffer())
    broadcast.close()

func scan_lan_rooms() -> void:
    discovered_rooms.clear()
    discovery_socket = PacketPeerUDP.new()
    discovery_socket.bind(7778)
    get_tree().create_timer(2.0).timeout.connect(_stop_lan_scan)

func _stop_lan_scan() -> void:
    if discovery_socket:
        discovery_socket.close()
        discovery_socket = null

func _process(_delta: float) -> void:
    if discovery_socket:
        if discovery_socket.get_available_packet_count() > 0:
            var packet := discovery_socket.get_packet()
            var json_str := packet.get_string_from_utf8()
            var data: Variant = JSON.parse_string(json_str)
            if data is Dictionary and data.get("type") == "host_announce":
                var sender := discovery_socket.get_packet_ip()
                discovered_rooms.append({"address": sender, "port": data.get("port", DEFAULT_PORT)})

@rpc("any_peer", "call_local", "reliable")
func sync_game_start(char1: String, char2: String, mode: String) -> void:
    Global.selected_characters = [char1, char2]
    Global.game_mode = mode
    Global.go_to_scene("res://scenes/GameArena.tscn")

func _on_peer_connected(id: int) -> void:
    connected_peers.append(id)
    player_connected.emit(id)
    print("Peer connected: %d" % id)

func _on_peer_disconnected(id: int) -> void:
    connected_peers.erase(id)
    player_disconnected.emit(id)

func _on_connected_to_server() -> void:
    print("Connected to server as peer %d" % multiplayer.get_unique_id())
    player_connected.emit(multiplayer.get_unique_id())

func _on_connection_failed() -> void:
    connection_failed.emit()

func _on_server_disconnected() -> void:
    disconnect_from_game()
    server_disconnected.emit()
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/networking/NetworkManager.gd
git commit -m "feat: add NetworkManager with ENet host/join and LAN discovery"
```

---

### Task 15: LobbyRoom Scene

**Files:**
- Create: `godot_project/scenes/LobbyRoom.tscn`
- Create: `godot_project/scripts/ui/LobbyRoom.gd`

- [ ] **Step 1: Create `godot_project/scripts/ui/LobbyRoom.gd`**

```gdscript
extends Control

@onready var room_code_label: Label = $RoomCodeLabel
@onready var status_label: Label = $StatusLabel
@onready var host_btn: Button = $Buttons/HostBtn
@onready var join_btn: Button = $Buttons/JoinBtn
@onready var join_input: LineEdit = $JoinPanel/CodeInput
@onready var join_confirm_btn: Button = $JoinPanel/ConfirmBtn
@onready var start_btn: Button = $StartBtn
@onready var player_list: VBoxContainer = $PlayerList
@onready var join_panel: Control = $JoinPanel

func _ready() -> void:
    start_btn.disabled = true
    join_panel.hide()
    host_btn.pressed.connect(_on_host)
    join_btn.pressed.connect(func(): join_panel.show())
    join_confirm_btn.pressed.connect(_on_join_confirm)
    start_btn.pressed.connect(_on_start)
    NetworkManager.player_connected.connect(_on_player_connected)
    NetworkManager.player_disconnected.connect(_on_player_disconnected)
    NetworkManager.connection_failed.connect(func(): status_label.text = "Connection failed!")

func _on_host() -> void:
    if NetworkManager.connection_type == "internet":
        _setup_internet_host()
    else:
        NetworkManager.host_game()
        NetworkManager.start_lan_discovery_host()
        room_code_label.text = "LAN Room — waiting for players..."
        status_label.text = "Hosting on LAN port 7777"
        start_btn.disabled = false

func _setup_internet_host() -> void:
    NetworkManager.host_game()
    var code := _generate_code()
    NetworkManager.room_code = code
    room_code_label.text = "Room Code: " + code
    status_label.text = "Share this code with your friend"
    start_btn.disabled = false

func _generate_code() -> String:
    const CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var code := ""
    for i in range(6):
        code += CHARS[randi() % CHARS.length()]
    return code

func _on_join_confirm() -> void:
    var code_or_ip := join_input.text.strip_edges()
    if code_or_ip.is_empty():
        return
    if NetworkManager.connection_type == "lan":
        NetworkManager.join_game(code_or_ip)
    else:
        # Connect via relay
        if NetworkManager.relay_client == null:
            NetworkManager.relay_client = RelayClient.new()
            add_child(NetworkManager.relay_client)
        NetworkManager.relay_client.join_room(code_or_ip)
    status_label.text = "Connecting..."

func _on_player_connected(id: int) -> void:
    var lbl := Label.new()
    lbl.name = "Peer_%d" % id
    lbl.text = "Player %d (peer %d)" % [player_list.get_child_count() + 1, id]
    player_list.add_child(lbl)
    status_label.text = "Players: %d" % NetworkManager.get_player_count()

func _on_player_disconnected(id: int) -> void:
    var node := player_list.find_child("Peer_%d" % id)
    if node:
        node.queue_free()

func _on_start() -> void:
    if not NetworkManager.is_host:
        return
    var chars := Global.selected_characters
    NetworkManager.sync_game_start.rpc(
        chars[0] if chars.size() > 0 else "Goku",
        chars[1] if chars.size() > 1 else "Naruto",
        Global.game_mode
    )
```

- [ ] **Step 2: Create `godot_project/scenes/LobbyRoom.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/LobbyRoom.gd" id="1"]

[node name="LobbyRoom" type="Control"]
script = ExtResource("1")
anchors_preset = 15

[node name="Background" type="ColorRect" parent="."]
color = Color(0.05, 0.05, 0.15, 1)
size = Vector2(1280, 720)

[node name="Title" type="Label" parent="."]
position = Vector2(440, 30)
text = "LOBBY"
theme_override_font_sizes/font_size = 48

[node name="RoomCodeLabel" type="Label" parent="."]
position = Vector2(340, 120)
size = Vector2(600, 50)
text = "Not hosting yet"
theme_override_font_sizes/font_size = 28
horizontal_alignment = 1

[node name="StatusLabel" type="Label" parent="."]
position = Vector2(340, 180)
size = Vector2(600, 40)
text = "Choose Host or Join"
horizontal_alignment = 1

[node name="Buttons" type="HBoxContainer" parent="."]
position = Vector2(440, 240)
size = Vector2(400, 60)

[node name="HostBtn" type="Button" parent="Buttons"]
text = "Host Room"
custom_minimum_size = Vector2(180, 55)

[node name="JoinBtn" type="Button" parent="Buttons"]
text = "Join Room"
custom_minimum_size = Vector2(180, 55)

[node name="JoinPanel" type="VBoxContainer" parent="."]
position = Vector2(440, 320)
visible = false

[node name="CodeInput" type="LineEdit" parent="JoinPanel"]
placeholder_text = "Enter code or IP"
custom_minimum_size = Vector2(300, 45)

[node name="ConfirmBtn" type="Button" parent="JoinPanel"]
text = "Connect"
custom_minimum_size = Vector2(150, 45)

[node name="PlayerList" type="VBoxContainer" parent="."]
position = Vector2(100, 300)
size = Vector2(300, 250)

[node name="PlayersTitle" type="Label" parent="PlayerList"]
text = "Players:"

[node name="StartBtn" type="Button" parent="."]
position = Vector2(540, 640)
text = "START GAME"
custom_minimum_size = Vector2(200, 55)
```

- [ ] **Step 3: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scenes/LobbyRoom.tscn godot_project/scripts/ui/LobbyRoom.gd
git commit -m "feat: add LobbyRoom with host/join for LAN and internet"
```

---

### Task 16: Rollback Netcode

**Files:**
- Create: `godot_project/scripts/networking/RollbackManager.gd`

- [ ] **Step 1: Create `godot_project/scripts/networking/RollbackManager.gd`**

```gdscript
extends Node
class_name RollbackManager

const BUFFER_SIZE := 8
const INPUT_BITS := 8  # 8 action flags

# Per-player input history: frame -> input bitmask
var input_history: Dictionary = {}   # peer_id -> Array[int]
var current_frame: int = 0
var local_peer_id: int = 1
var remote_peer_id: int = 2

signal input_ready(frame: int, p1_input: int, p2_input: int)

func _ready() -> void:
    set_process(false)

func setup(local_id: int, remote_id: int) -> void:
    local_peer_id = local_id
    remote_peer_id = remote_id
    input_history[local_id] = []
    input_history[remote_id] = []
    for i in range(BUFFER_SIZE):
        input_history[local_id].append(0)
        input_history[remote_id].append(0)
    current_frame = 0
    set_process(true)

func _process(_delta: float) -> void:
    pass  # Driven by GameArena per physics frame

func collect_and_send_input(local_input: int) -> void:
    var buf_idx := current_frame % BUFFER_SIZE
    input_history[local_peer_id][buf_idx] = local_input
    _send_input_to_peer(current_frame, local_input)

func _send_input_to_peer(frame: int, input_bitmask: int) -> void:
    if not multiplayer.has_multiplayer_peer():
        return
    receive_input.rpc(frame, input_bitmask)

@rpc("any_peer", "unreliable_ordered")
func receive_input(frame: int, input_bitmask: int) -> void:
    var sender := multiplayer.get_remote_sender_id()
    if sender != remote_peer_id:
        return
    var buf_idx := frame % BUFFER_SIZE
    if input_history.has(sender):
        input_history[sender][buf_idx] = input_bitmask

func get_inputs_for_frame(frame: int) -> Array[int]:
    var buf_idx := frame % BUFFER_SIZE
    var local_in := input_history[local_peer_id][buf_idx]
    # Predict remote: use last known if not received
    var remote_in := input_history[remote_peer_id][buf_idx]
    if remote_in == 0:
        # Predict: repeat previous frame's input
        var prev_idx := (frame - 1) % BUFFER_SIZE
        remote_in = input_history[remote_peer_id][prev_idx]
    return [local_in, remote_in]

func advance_frame() -> void:
    current_frame += 1
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/networking/RollbackManager.gd
git commit -m "feat: add RollbackManager with 8-frame input buffer"
```

---

### Task 17: Relay Client (WebSocket for Internet Play)

**Files:**
- Create: `godot_project/scripts/networking/RelayClient.gd`

- [ ] **Step 1: Create `godot_project/scripts/networking/RelayClient.gd`**

```gdscript
extends Node
class_name RelayClient

const RELAY_URL := "wss://your-relay-server.railway.app"  # Update after deploy

signal room_created(code: String)
signal peer_joined(peer_id: int)
signal message_received(data: PackedByteArray)
signal disconnected

var ws := WebSocketPeer.new()
var room_code_local: String = ""
var my_peer_id: int = 0
var connected: bool = false

func _ready() -> void:
    set_process(false)

func connect_to_relay() -> void:
    var err := ws.connect_to_url(RELAY_URL)
    if err != OK:
        push_error("Relay connect failed: " + error_string(err))
        return
    set_process(true)

func create_room() -> void:
    connect_to_relay()
    # Send create after connected (in _process)
    _pending_action = "create"

func join_room(code: String) -> void:
    room_code_local = code
    connect_to_relay()
    _pending_action = "join"

var _pending_action: String = ""

func _process(_delta: float) -> void:
    ws.poll()
    var state := ws.get_ready_state()
    match state:
        WebSocketPeer.STATE_OPEN:
            if not connected:
                connected = true
                _execute_pending()
            while ws.get_available_packet_count() > 0:
                var packet := ws.get_packet()
                _handle_packet(packet)
        WebSocketPeer.STATE_CLOSED:
            if connected:
                connected = false
                disconnected.emit()
            set_process(false)

func _execute_pending() -> void:
    match _pending_action:
        "create":
            _send_json({"action": "create"})
        "join":
            _send_json({"action": "join", "code": room_code_local})
    _pending_action = ""

func _handle_packet(packet: PackedByteArray) -> void:
    var text := packet.get_string_from_utf8()
    var msg: Variant = JSON.parse_string(text)
    if msg == null:
        message_received.emit(packet)
        return
    if msg is Dictionary:
        match msg.get("type", ""):
            "room_created":
                room_code_local = msg.get("code", "")
                NetworkManager.room_code = room_code_local
                room_created.emit(room_code_local)
            "peer_joined":
                var pid: int = msg.get("peer_id", 0)
                peer_joined.emit(pid)
                NetworkManager._on_peer_connected(pid)
            "relay":
                # Binary game data forwarded from relay
                var data_hex: String = msg.get("data", "")
                if not data_hex.is_empty():
                    message_received.emit(data_hex.hex_decode())

func send_to_peer(data: PackedByteArray) -> void:
    if not connected:
        return
    _send_json({
        "action": "relay",
        "room": room_code_local,
        "data": data.hex_encode()
    })

func _send_json(obj: Dictionary) -> void:
    var text := JSON.stringify(obj)
    ws.send_text(text)
```

- [ ] **Step 2: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scripts/networking/RelayClient.gd
git commit -m "feat: add RelayClient WebSocket for internet play"
```

---

## Phase 6: Relay Server

### Task 18: Node.js Relay Server

**Files:**
- Create: `relay_server/package.json`
- Create: `relay_server/server.js`

- [ ] **Step 1: Create `relay_server/package.json`**

```json
{
  "name": "doikhang-relay",
  "version": "1.0.0",
  "description": "WebSocket relay server for DoiKhang Anime",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js"
  },
  "dependencies": {
    "ws": "^8.17.0"
  },
  "engines": {
    "node": ">=18"
  }
}
```

- [ ] **Step 2: Create `relay_server/server.js`**

```javascript
const { WebSocketServer, WebSocket } = require('ws');

const PORT = process.env.PORT || 8765;
const wss = new WebSocketServer({ port: PORT });

// rooms: Map<code, { players: Map<peerId, WebSocket>, created: Date }>
const rooms = new Map();

let nextPeerId = 1000;

function generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function cleanupRooms() {
  const now = Date.now();
  for (const [code, room] of rooms) {
    // Remove dead sockets
    for (const [pid, ws] of room.players) {
      if (ws.readyState !== WebSocket.OPEN) room.players.delete(pid);
    }
    // Remove empty or old rooms (>2h)
    if (room.players.size === 0 || now - room.created > 7200000) {
      rooms.delete(code);
    }
  }
}

setInterval(cleanupRooms, 30000);

wss.on('connection', (ws) => {
  const peerId = nextPeerId++;
  ws.peerId = peerId;
  ws.roomCode = null;

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); }
    catch { return; }

    switch (msg.action) {
      case 'create': {
        let code = generateCode();
        while (rooms.has(code)) code = generateCode();
        rooms.set(code, { players: new Map([[peerId, ws]]), created: Date.now() });
        ws.roomCode = code;
        ws.send(JSON.stringify({ type: 'room_created', code, peer_id: peerId }));
        break;
      }

      case 'join': {
        const code = msg.code?.toUpperCase();
        if (!code || !rooms.has(code)) {
          ws.send(JSON.stringify({ type: 'error', message: 'Room not found' }));
          return;
        }
        const room = rooms.get(code);
        if (room.players.size >= 4) {
          ws.send(JSON.stringify({ type: 'error', message: 'Room full' }));
          return;
        }
        room.players.set(peerId, ws);
        ws.roomCode = code;
        ws.send(JSON.stringify({ type: 'joined', code, peer_id: peerId }));
        // Notify others in room
        for (const [pid, other] of room.players) {
          if (pid !== peerId && other.readyState === WebSocket.OPEN) {
            other.send(JSON.stringify({ type: 'peer_joined', peer_id: peerId }));
          }
        }
        break;
      }

      case 'relay': {
        const code = ws.roomCode;
        if (!code || !rooms.has(code)) return;
        const room = rooms.get(code);
        const data = msg.data;
        // Forward to all other players in room
        for (const [pid, other] of room.players) {
          if (pid !== peerId && other.readyState === WebSocket.OPEN) {
            other.send(JSON.stringify({ type: 'relay', from: peerId, data }));
          }
        }
        break;
      }

      case 'ping':
        ws.send(JSON.stringify({ type: 'pong' }));
        break;
    }
  });

  ws.on('close', () => {
    if (ws.roomCode && rooms.has(ws.roomCode)) {
      const room = rooms.get(ws.roomCode);
      room.players.delete(peerId);
      // Notify remaining players
      for (const [pid, other] of room.players) {
        if (other.readyState === WebSocket.OPEN) {
          other.send(JSON.stringify({ type: 'peer_left', peer_id: peerId }));
        }
      }
    }
  });

  ws.on('error', (err) => console.error('WS error peer %d:', peerId, err.message));
});

console.log(`Relay server running on port ${PORT}`);
console.log('Rooms cleanup every 30s. Max room age: 2h, max players: 4');
```

- [ ] **Step 3: Install dependencies**

```bash
cd /Users/luannt/doiKhang/relay_server
npm install
```

Expected output: `added 1 package (ws)`

- [ ] **Step 4: Test relay server locally**

```bash
cd /Users/luannt/doiKhang/relay_server
node server.js &
# Expected: "Relay server running on port 8765"
```

Open two terminal tabs and test with wscat or curl (or just check it starts without error):
```bash
# In another terminal: install wscat if needed
npx wscat -c ws://localhost:8765
# Type: {"action":"create"}
# Expected response: {"type":"room_created","code":"XXXXXX","peer_id":1000}
kill %1  # Stop background server
```

- [ ] **Step 5: Create railway.toml for deploy**

Create `relay_server/railway.toml`:
```toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "node server.js"
healthcheckPath = "/"
restartPolicyType = "ON_FAILURE"
```

- [ ] **Step 6: Commit relay server**

```bash
cd /Users/luannt/doiKhang
git add relay_server/
git commit -m "feat: add Node.js WebSocket relay server with room codes"
```

---

## Phase 7: Ground Physics & Arena Static Body

### Task 19: Wire Ground Collision in GameArena

The arena needs a StaticBody2D for the floor so characters land correctly.

**Files:**
- Modify: `godot_project/scenes/GameArena.tscn`
- Modify: `godot_project/scripts/game/ArenaScene.gd`

- [ ] **Step 1: Update GameArena.tscn — add proper ground StaticBody2D**

Replace the Ground node block in `GameArena.tscn` with:

```
[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(640, 610)

[node name="GroundCollision" type="CollisionShape2D" parent="Ground"]

[node name="GroundVisual" type="ColorRect" parent="Ground"]
color = Color(0.25, 0.18, 0.1, 1)
size = Vector2(1280, 120)
position = Vector2(-640, 0)
```

The GroundCollision shape needs to be set programmatically since .tscn can't serialize shapes easily. Add to `ArenaScene.gd`'s `_ready()`:

```gdscript
func _ready() -> void:
    # Setup ground collision shape
    var ground := $Ground
    var col := ground.get_node("GroundCollision")
    var shape := WorldBoundaryShape2D.new()
    col.shape = shape
    # ... rest of _ready
```

- [ ] **Step 2: Update ArenaScene._ready to setup ground**

In `godot_project/scripts/game/ArenaScene.gd`, update `_ready()`:

```gdscript
func _ready() -> void:
    # Setup ground collision
    var ground_col: CollisionShape2D = $Ground/GroundCollision
    var shape := WorldBoundaryShape2D.new()
    ground_col.shape = shape

    game_manager = GameManager.new()
    add_child(game_manager)
    game_manager.round_started.connect(_on_round_started)
    game_manager.round_ended.connect(_on_round_ended)
    game_manager.match_ended.connect(_on_match_ended)
    game_manager.timer_updated.connect(hud.update_timer)
    _spawn_players()
```

- [ ] **Step 3: Commit**

```bash
cd /Users/luannt/doiKhang
git add godot_project/scenes/GameArena.tscn godot_project/scripts/game/ArenaScene.gd
git commit -m "fix: add ground StaticBody2D collision for player landing"
```

---

## Phase 8: Final Wiring & Verification

### Task 20: Smoke Test — Verify Local 1v1 is Playable

- [ ] **Step 1: Verify all files exist**

```bash
find /Users/luannt/doiKhang/godot_project -name "*.gd" | sort
```

Expected output includes:
```
scripts/Global.gd
scripts/characters/CharacterBase.gd
scripts/characters/Conan.gd
scripts/characters/Doraemon.gd
scripts/characters/Goku.gd
scripts/characters/Hitbox.gd
scripts/characters/Hurtbox.gd
scripts/characters/Luffy.gd
scripts/characters/Naruto.gd
scripts/characters/Sakura.gd
scripts/game/AIController.gd
scripts/game/ArenaScene.gd
scripts/game/GameManager.gd
scripts/networking/NetworkManager.gd
scripts/networking/RelayClient.gd
scripts/networking/RollbackManager.gd
scripts/ui/CharacterSelect.gd
scripts/ui/HUD.gd
scripts/ui/LobbyRoom.gd
scripts/ui/MainMenu.gd
scripts/ui/ResultScreen.gd
```

- [ ] **Step 2: Open project in Godot 4**

```bash
# If Godot 4 is installed:
open /Users/luannt/doiKhang/godot_project/project.godot
# Or: godot4 /Users/luannt/doiKhang/godot_project/project.godot
```

- [ ] **Step 3: Fix any import/script errors in Godot editor**

Common issues to check:
- Missing `@onready` nodes in scene: ensure node names in .tscn match names used in scripts
- `Hitbox` / `Hurtbox` / `CharacterBase` class names: Godot needs these scripts to be pre-loaded or in the same directory
- Add class_name declarations if needed (already done in the scripts above)

- [ ] **Step 4: Run local 1v1 match**

In Godot editor:
1. Press F5 (or Play button)
2. Click "Play Local"
3. Player 1 selects a character, click Confirm
4. Player 2 selects a character, click Confirm
5. Click "START FIGHT!"
6. Verify: both characters appear on arena, can move (WASD / Arrow keys)
7. Verify: pressing J attacks, K fires special (when SP > 30)
8. Verify: HP bars decrease when hit
9. Verify: Round ends when HP reaches 0
10. Verify: Result screen shows winner

- [ ] **Step 5: Test LAN multiplayer**

Run two instances of Godot (or export and run two executables on same network):
1. Instance 1: Play LAN → Host Room → note LAN IP
2. Instance 2: Play LAN → Join Room → enter host IP → connect
3. Both: Select characters → Host clicks Start
4. Verify: both see the arena and can control their character

- [ ] **Step 6: Commit final state**

```bash
cd /Users/luannt/doiKhang
git add -A
git commit -m "feat: complete anime fighting game MVP with LAN/internet multiplayer"
```

---

## Appendix: Deploy Relay Server

After Task 18, deploy the relay server:

```bash
# Option A: Railway (free tier)
cd /Users/luannt/doiKhang/relay_server
railway init
railway up
# Get URL from Railway dashboard, e.g. https://doikhang-relay.railway.app

# Option B: Render (free tier)
# Push relay_server/ to a GitHub repo
# Create new Web Service on render.com → connect repo → "node server.js"
```

Then update `RelayClient.gd` line:
```gdscript
const RELAY_URL := "wss://your-actual-deployed-url.railway.app"
```

---

## Summary Checklist

- [ ] Task 1: Project structure + Global.gd + input map
- [ ] Task 2: CharacterBase physics + state machine
- [ ] Task 3: Hitbox / Hurtbox system
- [ ] Task 4: Goku (Kamehameha, SSJ)
- [ ] Task 5: Naruto (Rasengan, Shadow Clone)
- [ ] Task 6: Luffy, Conan, Doraemon, Sakura
- [ ] Task 7: GameManager (rounds, win conditions)
- [ ] Task 8: HUD (HP bars, timer, round display)
- [ ] Task 9: AIController (3 difficulties)
- [ ] Task 10: GameArena scene + ArenaScene.gd
- [ ] Task 11: MainMenu scene
- [ ] Task 12: CharacterSelect scene
- [ ] Task 13: ResultScreen scene
- [ ] Task 14: NetworkManager (ENet + LAN discovery)
- [ ] Task 15: LobbyRoom scene
- [ ] Task 16: RollbackManager (8-frame input buffer)
- [ ] Task 17: RelayClient (WebSocket)
- [ ] Task 18: Node.js relay server + deploy
- [ ] Task 19: Ground collision wiring
- [ ] Task 20: Smoke test — local 1v1 playable
