extends CharacterBody3D

@export var Speed: float = 4.0
@export var JumpCurve: Curve
@export var JumpVelocity: float = 10.5

var input_move: Vector2

var input_just_jump: bool

var input_fire: bool
var input_just_fire: bool

var look_speed: float = 1.0
var x_look_clamp_degrees: float = 90.0

var jump_t: float
var jumping: bool

@onready var cam: Camera3D = $Camera3D

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
	var fwd: Vector3 = -global_basis.z
	fwd.y = 0
	fwd = fwd.normalized()

	var right: Vector3 = global_basis.x
	right.y = 0
	right = right.normalized()

	var v: Vector3 = vel_calc(input_move, fwd, right, Speed)
	velocity.x = v.x
	velocity.z = v.z

	if input_just_jump:
		jump()
	
	if jumping:
		jump_t = clamp(jump_t + delta, 0, 1)
		var yv: float = JumpCurve.sample(jump_t) * JumpVelocity
		velocity.y += yv
	
func end_step(delta: float) -> void:
	if is_on_floor():
		jumping = false
		velocity.y = 0
	else:
		velocity += get_gravity()

func jump() -> void:
	if jumping:
		return
	
	jumping = true
	jump_t = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam.global_rotation_degrees.x = clamp(cam.global_rotation_degrees.x - event.relative.y * look_speed, -x_look_clamp_degrees, x_look_clamp_degrees)
		global_rotation_degrees.y = global_rotation_degrees.y - event.relative.x * look_speed

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("Fire"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	take_input()
	begin_step(delta)
	move_and_slide()
	end_step(delta)
	print(get_real_velocity())
