class_name NPC
extends CharacterBody3D

@export_subgroup("Movement")
@export var Speed: float = 1.0
@export var KnockbackFrictionHorizontal: float = 4.0
@export var KnockbackFrictionVertical: float = 0.0

var move: Vector3
var knockback: Vector3

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
