class_name Player
extends CharacterBody3D

@export_subgroup("Movement")
@export var Speed: float = 8.0
@export var JumpCurve: Curve
@export var JumpVelocity: float = 6.33
@export var JumpDuration: float = 1.0
@export var AirFriction: float = 0.85
@export var BunnyHopMultiplier: float = 2.0
@export var BunnyHopMax: float = 4.0
@export var BunnyHopDeceleration: float = 4.0
@export var BunnyHopGravityMultiplierMin: float = 0.95
@export var BunnyHopAirFrictionToGravityMultiplier: float = 0.33
@export var WallKickCurve: Curve
@export var WallKickWallBias: float = 4.0
@export var WallKickVerticalBias: float = 1.0
@export var WallKickVelocity: float = 5.5
@export var WallKickDuration: float = 1.0
@export var KnockbackFrictionHorizontal: float = 32.0
@export var KnockbackFrictionVertical: float = 64.0
@export_subgroup("Camera")
@export var LeanAmountDegrees: float = 2.0
@export var LeanSpeed: float = 16.0
@export var ViewBobFreq: float = 1.0
@export var ViewBobAmp: float = 6.7
@export var FovKick: float = 110.0
@export var FovSpeed: float = 64.0
@export var ShakeMultiplier: float = 2.0
@export_subgroup("Combat")
@export var PushVelocity: float = 4.0
@export var DunkVelocity: float = 6.0
@export var ProjectileFxSpeed: float = 4.0
@export var PushSelfVelocity: float = 4.0

var input_move: Vector2

var input_just_jump: bool

var input_fire: bool
var input_just_fire: bool

var look_speed: float = 1.0
var x_look_clamp_degrees: float = 90.0

var jump_t: float
var jumping: bool
var jump_dir: Vector3 = Vector3.UP

var wall_kick_t: float
var wall_kicking: bool
var wall_kick_dir: Vector3 = Vector3.UP
var last_wall_kick_dir: Vector3 = Vector3.ZERO

var current_air_friction: float

var was_on_floor: bool

var view_bob_amount: float

var attacking: bool

var o_cam_fov: float
var next_cam_fov: float

var knockback: Vector3

var cam_shaking: bool
var shake_this_frame: bool
var o_cam_position: Vector3
var cam_shake_amount: float

var push_spr: AnimatedSprite3D
var init_push_spr_gp: Vector3

var coins: int
var last_counter: Control

@onready var cam: Camera3D = $Camera3D
@onready var view_cam: Camera3D = $Camera3D/SubViewportContainer/SubViewport/View
@onready var bhop_timer: Timer = $BunnyHopTimer
@onready var lines_left: GPUParticles3D = $Camera3D/SubViewportContainer/SubViewport/View/AnimLineLeft
@onready var lines_right: GPUParticles3D = $Camera3D/SubViewportContainer/SubViewport/View/AnimLineRight
@onready var hands: Node3D = $Camera3D/SubViewportContainer/SubViewport/Hands
@onready var left_hand_spr: AnimatedSprite3D = $Camera3D/SubViewportContainer/SubViewport/Hands/Left
@onready var right_hand_spr: AnimatedSprite3D = $Camera3D/SubViewportContainer/SubViewport/Hands/Right
@onready var interact_cast: ShapeCast3D = $Camera3D/Interact
@onready var attack_timer: Timer = $AttackTimer
@onready var wall_kick_cast: ShapeCast3D = $WallKick
@onready var cam_shake_timer: Timer = $CameraShakeTimer

func take_input() -> void:
	look_speed = get_node("/root/Main/PauseMenu").look.value

	input_move = Input.get_vector("MoveLeft", "MoveRight", "MoveBackward", "MoveForward")

	input_just_jump = Input.is_action_just_pressed("Jump")

	input_fire = Input.is_action_pressed("Fire")
	input_just_fire = Input.is_action_just_pressed("Fire")

func vel_calc(i: Vector2, fwd: Vector3, right: Vector3, s: float) -> Vector3:
	var f: Vector3 = i.y * fwd
	var r: Vector3 = i.x * right
	var v: Vector3 = (f + r).normalized() * s
	return v

func can_wall_kick() -> Vector3:
	if !is_on_floor():
		wall_kick_cast.force_update_transform()
		wall_kick_cast.force_shapecast_update()

		for i in wall_kick_cast.get_collision_count():
			if !is_instance_valid(wall_kick_cast.get_collider(i)):
				continue
			
			var n: Vector3 = wall_kick_cast.get_collision_normal(i)
			if n.is_equal_approx(Vector3.ZERO):
				continue
			
			if rad_to_deg(acos(n.dot(Vector3.UP))) > 45 + 0.01:
				return n
	
	return Vector3.ZERO

func begin_step(delta: float) -> void:
	determine_move_vel()
	
	# Jump / wall kick input
	if input_just_jump:
		var wn: Vector3 = can_wall_kick()
		if !wn.is_equal_approx(Vector3.ZERO):
			wall_kick(wn)
		else:
			jump()

	# Attack input
	if input_just_fire:
		attack()
		
	process_jump_and_wall_kick(delta)
	process_attack()
	multiply_air_friction()
	process_knockback(delta)

func end_step(delta: float) -> void:
	# Cancel velocity and jump state when we hit the floor.
	if is_on_floor():
		jumping = false
		wall_kicking = false
		last_wall_kick_dir = Vector3.ZERO
		velocity.y = 0
		current_air_friction = move_toward(current_air_friction, AirFriction, delta * BunnyHopDeceleration)

		if !was_on_floor:
			bhop_timer.start()
	else:
		var grav_mod: float = 1.0
		if current_air_friction > 1.0:
			grav_mod = clamp((1.0 / (current_air_friction * BunnyHopAirFrictionToGravityMultiplier)), BunnyHopGravityMultiplierMin, 1.0)
		velocity += get_gravity() * grav_mod

	was_on_floor = is_on_floor()

func determine_move_vel() -> void:
	# Grab directions...
	var fwd: Vector3 = -global_basis.z
	fwd.y = 0
	fwd = fwd.normalized()

	var right: Vector3 = global_basis.x
	right.y = 0
	right = right.normalized()

	# Horizontal velocity calc
	var v: Vector3 = vel_calc(input_move, fwd, right, Speed)

	velocity.x = v.x
	velocity.z = v.z

func process_knockback(delta: float) -> void:
	velocity += knockback
	knockback.x = move_toward(knockback.x, 0.0, delta * KnockbackFrictionHorizontal)
	knockback.y = move_toward(knockback.y, 0.0, delta * KnockbackFrictionVertical)
	knockback.z = move_toward(knockback.z, 0.0, delta * KnockbackFrictionHorizontal)

	if is_on_wall():
		knockback = Vector3.ZERO

func process_jump_and_wall_kick(delta: float) -> void:
	# Jump / wall kick proc
	if wall_kicking:
		wall_kick_t = clamp(wall_kick_t + delta / WallKickDuration, 0, 1)
		var wv: float = WallKickCurve.sample(wall_kick_t) * WallKickVelocity
		var wall_vel: Vector3 = (wall_kick_dir * WallKickWallBias + Vector3.UP * WallKickVerticalBias).normalized() * wv
		velocity += wall_vel

		if wall_kick_t >= 1.0:
			wall_kicking = false
	elif jumping:
		jump_t = clamp(jump_t + delta / JumpDuration, 0, 1)
		var yv: float = JumpCurve.sample(jump_t) * JumpVelocity
		velocity += jump_dir * yv

func process_attack() -> void:
	if attacking && attack_timer.is_stopped():
		attacking = false
	
	if push_spr != null:
		var t: float = clamp(((attack_timer.wait_time - attack_timer.time_left) / attack_timer.wait_time) * ProjectileFxSpeed, 0.0, 1.0)
		push_spr.global_position = lerp(init_push_spr_gp, init_push_spr_gp - cam.global_basis.z * (interact_cast.shape as SphereShape3D).radius, t)
		var col: Color = Color(-randf() + randf(), -randf() + randf(), -randf() + randf(), 1.0)
		push_spr.modulate = col
		push_spr.get_node("OmniLight3D").light_color = col


func process_cam_shake(delta: float) -> void:
	if !cam_shake_timer.is_stopped():
		if shake_this_frame:
			cam.position += Vector3(-randf() + randf(), -randf() + randf(), -randf() + randf()).normalized() * cam_shake_amount * delta * ShakeMultiplier
		else:
			cam.position = o_cam_position
		
		shake_this_frame = !shake_this_frame
	else:
		cam.position = o_cam_position


func process_cam_lean(delta: float) -> void:
	# Cam lean
	cam.rotation_degrees.z = move_toward(cam.rotation_degrees.z, -input_move.x * LeanAmountDegrees, delta * LeanSpeed)

func process_view_bob(delta: float) -> void:
	# View bob
	var hv: Vector3 = velocity
	hv.y = 0
	view_bob_amount += hv.length()
	view_bob_amount = move_toward(view_bob_amount, 0, delta)
	left_hand_spr.position.y = sin((ViewBobFreq / 1000.0) * view_bob_amount) * ViewBobAmp / 1000.0
	right_hand_spr.position.y = sin((ViewBobFreq / 1000.0) * view_bob_amount) * ViewBobAmp / 1000.0

func process_fov_kick(delta: float) -> void:
	# FOV Kick
	cam.fov = move_toward(cam.fov, next_cam_fov, delta * FovSpeed)

	if !jumping:
		next_cam_fov = o_cam_fov

func multiply_air_friction() -> void:
	# Air velocity multiplier (bhop)
	if !is_on_floor() || current_air_friction > AirFriction:
		velocity.x *= current_air_friction
		velocity.z *= current_air_friction

func inc_air_friction() -> void:
	current_air_friction = clamp(current_air_friction * BunnyHopMultiplier, AirFriction, BunnyHopMax)

func attack() -> void:
	if attacking:
		return

	attacking = true
	attack_timer.start()

	left_hand_spr.play("push")
	right_hand_spr.play("push")
	var spr: AnimatedSprite3D = preload("res://Scenes/push_fx.tscn").instantiate()
	get_parent().add_child(spr)
	push_spr = spr
	push_spr.global_position = cam.global_position - cam.global_basis.z
	push_spr.global_rotation = cam.global_rotation
	init_push_spr_gp = push_spr.global_position
	knockback += cam.global_basis.z * PushSelfVelocity

	for i in interact_cast.get_collision_count():
		var obj: Object = interact_cast.get_collider(i)

		if !is_instance_valid(obj):
			continue

		if obj is NPC:
			var v: Vector3 = -interact_cast.get_collision_normal(i) * PushVelocity
			if !obj.is_on_floor() && obj.Dunkable:
				v = Vector3.DOWN * DunkVelocity
				cam.look_at(obj.global_position)
				cam.rotation.z = 0
				cam.scale = Vector3.ONE
				print("dunk")
			obj.knockback += v

func jump() -> void:
	if jumping:
		return
	
	jumping = true
	jump_t = 0.0

	if !bhop_timer.is_stopped():
		inc_air_friction()
		lines_left.play()
		lines_right.play()

	next_cam_fov = FovKick

func wall_kick(wn: Vector3) -> void:
	if last_wall_kick_dir.is_equal_approx(wn) || wn.is_equal_approx(Vector3.ZERO):
		return
	
	wall_kicking = true
	wall_kick_t = 0.0
	last_wall_kick_dir = wall_kick_dir
	wall_kick_dir = wn
	velocity.y = 0
	inc_air_friction()

	next_cam_fov = FovKick

	var parts_scn: PackedScene = preload("res://Scenes/wall_kick_particles.tscn")
	var p: GPUParticles3D = parts_scn.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.look_at(p.global_position + wall_kick_dir * 0.1)
	p.restart()

func shake_cam(amount: float) -> void:
	cam.position = o_cam_position
	shake_this_frame = false
	cam_shake_timer.start()
	cam_shake_amount = amount

func inc_coins() -> void:
	if is_instance_valid(last_counter):
		last_counter.queue_free()
		last_counter = null
	
	coins = clamp(coins + 1, 0, INF)
	var counter_scn: PackedScene = preload("res://Scenes/coin_counter.tscn")
	var counter: Control = counter_scn.instantiate()
	get_parent().add_child(counter)
	counter.label.text = str(coins)
	last_counter = counter

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	current_air_friction = AirFriction

	o_cam_fov = cam.fov
	o_cam_position = cam.position

	attack_timer.connect("timeout", _on_attack_timeout)

	left_hand_spr.play("default")
	right_hand_spr.play("default")

func _on_attack_timeout() -> void:
	attacking = false
	left_hand_spr.play("default")
	right_hand_spr.play("default")

func _input(event: InputEvent) -> void:
	# Rotate camera on x, rotate root on y
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam.global_rotation_degrees.x = clamp(cam.global_rotation_degrees.x - event.relative.y * look_speed, -x_look_clamp_degrees, x_look_clamp_degrees)
		global_rotation_degrees.y = global_rotation_degrees.y - event.relative.x * look_speed

func _process(delta: float) -> void:
	process_cam_lean(delta)
	process_view_bob(delta)
	process_fov_kick(delta)

func _physics_process(delta: float) -> void:
	take_input()
	begin_step(delta)
	move_and_slide()
	end_step(delta)

	process_cam_shake(delta)
