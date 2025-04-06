class_name NPC
extends CharacterBody3D

const KB_LENGTH_MIN: float = 0.1

enum MoveBehavior {
	STRAFE,
}

@export_subgroup("Movement")
@export var Speed: float = 3.0
@export var KnockbackFrictionHorizontal: float = 4.0
@export var KnockbackFrictionVertical: float = 0.0
@export var FlipSpeed: float = 1.0
@export_subgroup("Behavior")
@export var Behavior: MoveBehavior = MoveBehavior.STRAFE
@export var CombatRadius: float = 3.0
@export var StrafeFreq: float = 0.01
@export var StrafeAmp: float = 6.0
@export var WeaponSpriteName: String = "Spear"

var move: Vector3
var knockback: Vector3
var flip_t: float
var weapon_spr: Sprite3D
var o_x_weapon: float

@onready var sprite: Sprite3D = $Sprite3D
@onready var kb_cast: ShapeCast3D = $PushCast
@onready var player: Player = %Player
@onready var nav: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	weapon_spr = get_node(WeaponSpriteName)
	o_x_weapon = weapon_spr.position.x

func _physics_process(delta: float) -> void:
	look_at(player.global_position)

	move = Vector3.ZERO

	if player.global_position.distance_to(global_position) > CombatRadius:
		nav.target_position = player.global_position
		var next: Vector3 = nav.get_next_path_position()
		print(next)
		move = (next - global_position).normalized() * Speed
	else:
		if Behavior == MoveBehavior.STRAFE:
			var v: Vector3 = global_basis.x * sin(Time.get_ticks_msec() * StrafeFreq) * StrafeAmp
			move.x = v.x
			move.z = v.z

	knockback.x = move_toward(knockback.x, 0, delta * KnockbackFrictionHorizontal)
	knockback.y = move_toward(knockback.y, 0, delta * KnockbackFrictionVertical)
	knockback.z = move_toward(knockback.z, 0, delta * KnockbackFrictionHorizontal)

	var xz_kb: Vector3 = knockback
	xz_kb.y = 0

	if xz_kb.length() > KB_LENGTH_MIN:
		move = Vector3.ZERO
		
		kb_cast.enabled = false

		if Time.get_ticks_msec() % 4 == 0:
			sprite.modulate = Color.RED
		else:
			sprite.modulate = Color.WHITE
	else:
		sprite.modulate = Color.WHITE
		kb_cast.enabled = true

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
		weapon_spr.position.x = -weapon_spr.position.x
		flip_t = 0.0
