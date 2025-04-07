class_name NPC
extends CharacterBody3D

const VEL_LENGTH_MIN: float = 1.0

enum MoveBehavior {
	NONE,
	STRAFE,
	BOUNCE_NAVIGATE,
	CHASE,
	FLEE,
	BOUNCE,
}

enum FlipType {
	HORIZONTAL,
	VERTICAL,
}

@export_subgroup("Movement")
@export var Speed: float = 3.0
@export var KnockbackFrictionHorizontal: float = 4.0
@export var KnockbackFrictionVertical: float = 0.0
@export var GravityScale: float = 1.0
@export_subgroup("Behavior")
@export var Behavior: MoveBehavior = MoveBehavior.STRAFE
@export var CombatRadius: float = 3.0
@export var SightRadius: float = 8.0
@export var StrafeFreq: float = 0.01
@export var StrafeAmp: float = 6.0
@export var WeaponSpriteName: String = "Spear"
@export var BounceRadius: float = 8.0
@export var SeenSay: Array[String] = []
@export var RepeatSeenSay: bool = false
@export var Dunkable: bool = true
@export_subgroup("FX")
@export var IdleTexture: Texture
@export var FlipSpeed: float = 1.0
@export var FlipMode: FlipType = FlipType.HORIZONTAL
@export var NoticeAudio: AudioStream

var move: Vector3
var knockback: Vector3

var flip_t: float

var weapon_spr: Sprite3D

var rand_dir: Vector2
var seen_player: bool

var o_texture: Texture

var dust_scn: PackedScene = preload("res://Scenes/wall_kick_particles.tscn")

@onready var sprite: Sprite3D = $Sprite3D
@onready var kb_cast: ShapeCast3D = $PushCast
@onready var player: Player = %Player
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var typewriter: Typewriter = $Say

func randomize_dir() -> void:
	rand_dir = Vector2(-randf() + randf(), -randf() + randf()).normalized()

func reflect_dir() -> void:
	var d: Vector2 = rand_dir
	rand_dir.x = -d.y
	rand_dir.y = d.x

func notice_player() -> void:
	if !seen_player && SeenSay.size() > 0:
		seen_player = true
		typewriter.Say = SeenSay.pick_random()
		typewriter.reset()
		Utils.gen_sound(NoticeAudio, self)

func process_behavior() -> void:
	var dist_to_player: float = player.global_position.distance_to(global_position)
	if dist_to_player > CombatRadius && dist_to_player < SightRadius && Behavior != MoveBehavior.NONE && Behavior != MoveBehavior.BOUNCE:
		nav.target_position = player.global_position
		var next: Vector3 = nav.get_next_path_position()
		move = (next - global_position).normalized() * Speed
		
		if Behavior == MoveBehavior.FLEE:
			move = Vector3.ZERO

		notice_player()

	elif dist_to_player < CombatRadius:
		if Behavior == MoveBehavior.STRAFE:
			var v: Vector3 = global_basis.x * sin(Time.get_ticks_msec() * StrafeFreq) * StrafeAmp
			move.x = v.x
			move.z = v.z
		elif Behavior == MoveBehavior.BOUNCE_NAVIGATE:
			var v: Vector3 = Vector3(rand_dir.x, 0, rand_dir.y).normalized() * BounceRadius
			nav.target_position = global_position + v
			var next: Vector3 = nav.get_next_path_position()
			move = (next - global_position).normalized() * Speed

			if is_on_wall() || !nav.is_target_reachable() || nav.is_target_reached():
				reflect_dir()
		elif Behavior == MoveBehavior.CHASE:
			nav.target_position = player.global_position
			var next: Vector3 = nav.get_next_path_position()
			move = (next - global_position).normalized() * Speed
		elif Behavior == MoveBehavior.FLEE:
			var v: Vector3 = (global_position - player.global_position).normalized() * Speed
			move = v
		elif Behavior == MoveBehavior.BOUNCE:
			var v: Vector3 = Vector3(rand_dir.x, 0, rand_dir.y).normalized() * BounceRadius
			move = v
			if is_on_wall():
				reflect_dir()
	elif dist_to_player > SightRadius:
		if RepeatSeenSay:
			seen_player = false
	
func process_knockback(delta: float) -> void:
	knockback.x = move_toward(knockback.x, 0, delta * KnockbackFrictionHorizontal)
	knockback.y = move_toward(knockback.y, 0, delta * KnockbackFrictionVertical)
	knockback.z = move_toward(knockback.z, 0, delta * KnockbackFrictionHorizontal)

	var xz_kb: Vector3 = knockback
	xz_kb.y = 0

	if xz_kb.length() > VEL_LENGTH_MIN:
		move = Vector3.ZERO
		
		kb_cast.enabled = false

		if Time.get_ticks_msec() % 8 == 0:
			var dust: GPUParticles3D = dust_scn.instantiate()
			add_child(dust)
			dust.restart()
		
		if Time.get_ticks_msec() % 4 == 0:
			sprite.modulate = Color.RED
		else:
			sprite.modulate = Color.WHITE
	else:
		sprite.modulate = Color.WHITE
		kb_cast.enabled = true

func process_flip(delta: float) -> void:
	var xz_vel: Vector3 = velocity
	xz_vel.y = 0

	flip_t = clamp(flip_t + delta * FlipSpeed * xz_vel.length(), 0.0, 1.0)

	if flip_t >= 1.0:
		if FlipMode == FlipType.HORIZONTAL:
			sprite.flip_h = !sprite.flip_h
		elif FlipMode == FlipType.VERTICAL:
			sprite.flip_v = !sprite.flip_v
		
		flip_t = 0.0

		if weapon_spr != null:
			weapon_spr.position.x = -weapon_spr.position.x

func process_textures() -> void:
	var xz_vel: Vector3 = velocity
	xz_vel.y = 0

	if xz_vel.length() < VEL_LENGTH_MIN:
		if IdleTexture != null:
			sprite.texture = IdleTexture
	else:
		sprite.texture = o_texture


func _ready() -> void:
	add_to_group("NPC")
	
	weapon_spr = get_node_or_null(WeaponSpriteName)
	o_texture = sprite.texture

	randomize_dir()

func _physics_process(delta: float) -> void:
	look_at(player.global_position)

	move = Vector3.ZERO

	process_behavior()
	process_knockback(delta)

	velocity.x = move.x + knockback.x
	velocity.y += knockback.y
	velocity.z = move.z + knockback.z

	if !is_on_floor():
		velocity += get_gravity() * GravityScale

	move_and_slide()

	if is_on_floor():
		velocity.y = 0

	process_flip(delta)
	process_textures()
