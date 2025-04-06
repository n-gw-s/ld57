class_name NPC
extends CharacterBody3D

@export_subgroup("Movement")
@export var Speed: float = 1.0
@export var KnockbackFrictionHorizontal: float = 4.0
@export var KnockbackFrictionVertical: float = 0.0
@export var FlipSpeed: float = 1.0

var move: Vector3
var knockback: Vector3
var flip_t: float

@onready var sprite: Sprite3D = $Sprite3D

func _physics_process(delta: float) -> void:
	knockback.x = move_toward(knockback.x, 0, delta * KnockbackFrictionHorizontal)
	knockback.y = move_toward(knockback.y, 0, delta * KnockbackFrictionVertical)
	knockback.z = move_toward(knockback.z, 0, delta * KnockbackFrictionHorizontal)

	velocity.x = move.x + knockback.x
	velocity.y += knockback.y
	velocity.z = move.z + knockback.z

	if !is_on_floor():
		velocity += get_gravity()

	move_and_slide()

	if is_on_floor():
		velocity.y = 0

	var xz_vel: Vector3 = velocity
	xz_vel.y = 0

	flip_t = clamp(flip_t + delta * FlipSpeed * xz_vel.length(), 0.0, 1.0)

	if flip_t >= 1.0:
		sprite.flip_h = !sprite.flip_h
		flip_t = 0.0
