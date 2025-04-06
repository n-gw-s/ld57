extends CharacterBody3D

@export_subgroup("Movement")
@export var Speed: float = 4.0
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
@export var WallKickForwardBias: float = 1.0
@export var WallKickVelocity: float = 4.0
@export var WallKickDuration: float = 1.0
@export_subgroup("Camera")
@export var LeanAmountDegrees: float = 2.0
@export var LeanSpeed: float = 16.0
@export var ViewBobFreq: float = 0.001
@export var ViewBobAmp: float = 0.067

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
var wall_kick_dir: = Vector3.UP

var current_air_friction: float

var was_on_floor: bool

var view_bob_amount: float

@onready var cam: Camera3D = $Camera3D
@onready var view_cam: Camera3D = $Camera3D/SubViewportContainer/SubViewport/View
@onready var bhop_timer: Timer = $BunnyHopTimer
@onready var lines_left: GPUParticles3D = $Camera3D/SubViewportContainer/SubViewport/View/AnimLineLeft
@onready var lines_right: GPUParticles3D = $Camera3D/SubViewportContainer/SubViewport/View/AnimLineRight
@onready var hands: Node3D = $Camera3D/SubViewportContainer/SubViewport/Hands
@onready var left_hand_spr: Sprite3D = $Camera3D/SubViewportContainer/SubViewport/Hands/Left
@onready var right_hand_spr: Sprite3D = $Camera3D/SubViewportContainer/SubViewport/Hands/Right

func take_input() -> void:
	input_move = Input.get_vector("MoveLeft", "MoveRight", "MoveBackward", "MoveForward")

	input_just_jump = Input.is_action_just_pressed("Jump")

	input_fire = Input.is_action_pressed("Fire")
	input_just_fire = Input.is_action_just_pressed("Fire")

func vel_calc(i: Vector2, fwd: Vector3, right: Vector3, s: float) -> Vector3:
	var f: Vector3 = i.y * fwd
	var r: Vector3 = i.x * right
	var v: Vector3 = (f + r).normalized() * s
	return v

func begin_step(delta: float) -> void:
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
	
	# Jump / wall kick input
	if input_just_jump:
		if is_on_wall_only():
			wall_kick()
		else:
			jump()
	
	# Wall kick proc
	if wall_kicking:
		wall_kick_t = clamp(wall_kick_t + delta / WallKickDuration, 0, 1)
		var wv: float = WallKickCurve.sample(wall_kick_t) * WallKickVelocity
		var f: Vector3 = -global_basis.z
		f.y = 0
		var wall_vel: Vector3 = (wall_kick_dir * WallKickWallBias + Vector3.UP * WallKickVerticalBias + f * WallKickForwardBias).normalized() * wv
		velocity.x = wall_vel.x
		velocity.y += wall_vel.y
		velocity.z = wall_vel.z

		if wall_kick_t >= 1.0:
			wall_kicking = false
	
	# Jump proc
	if jumping:
		jump_t = clamp(jump_t + delta / JumpDuration, 0, 1)
		var yv: float = JumpCurve.sample(jump_t) * JumpVelocity
		velocity += jump_dir * yv
	
	# Air velocity multiplier (bhop)
	if !is_on_floor() || current_air_friction > AirFriction:
		velocity.x *= current_air_friction
		velocity.z *= current_air_friction

func end_step(delta: float) -> void:
	# Cancel velocity and jump state when we hit the floor.
	if is_on_floor():
		jumping = false
		wall_kicking = false
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

func jump() -> void:
	if jumping:
		return
	
	jumping = true
	jump_t = 0.0

	if !bhop_timer.is_stopped():
		current_air_friction = clamp(current_air_friction * BunnyHopMultiplier, AirFriction, BunnyHopMax)
		lines_left.play()
		lines_right.play()

func wall_kick() -> void:
	if !is_on_wall_only():
		return
	
	wall_kicking = true
	wall_kick_t = 0.0
	wall_kick_dir = get_wall_normal()
	velocity.y = 0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	current_air_friction = AirFriction

func _input(event: InputEvent) -> void:
	# Rotate camera on x, rotate root on y
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam.global_rotation_degrees.x = clamp(cam.global_rotation_degrees.x - event.relative.y * look_speed, -x_look_clamp_degrees, x_look_clamp_degrees)
		global_rotation_degrees.y = global_rotation_degrees.y - event.relative.x * look_speed

func _process(delta: float) -> void:
	# Mouse handling
	if Input.is_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("Fire"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Cam lean
	cam.rotation_degrees.z = move_toward(cam.rotation_degrees.z, -input_move.x * LeanAmountDegrees, delta * LeanSpeed)

	# View bob
	var hv: Vector3 = velocity
	hv.y = 0
	view_bob_amount += hv.length()
	view_bob_amount = move_toward(view_bob_amount, 0, delta)
	left_hand_spr.position.y = sin(ViewBobFreq * view_bob_amount) * ViewBobAmp
	right_hand_spr.position.y = sin(ViewBobFreq * view_bob_amount) * ViewBobAmp

func _physics_process(delta: float) -> void:
	take_input()
	begin_step(delta)
	move_and_slide()
	end_step(delta)
