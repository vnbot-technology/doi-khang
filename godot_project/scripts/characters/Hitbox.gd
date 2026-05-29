extends Area2D
class_name Hitbox

@export var damage: float = 15.0
@export var knockback_force: float = 280.0

var owner_character: CharacterBase = null
var already_hit: Array[CharacterBase] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false

func reset() -> void:
	already_hit.clear()

func _on_area_entered(area: Area2D) -> void:
	if not (area is Hurtbox):
		return
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
