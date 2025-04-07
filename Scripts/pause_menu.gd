extends Control

@onready var look: Slider = $Background/Look/Slider

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		visible = !visible

		if visible:
			get_tree().paused = true
			process_mode = Node.PROCESS_MODE_WHEN_PAUSED
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			get_tree().paused = false
			process_mode = Node.PROCESS_MODE_INHERIT
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
