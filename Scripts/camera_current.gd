extends Camera3D

var t: float
var o_rot_y: float

func _ready() -> void:
	o_rot_y = rotation_degrees.y
	make_current()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _process(delta: float) -> void:
	t += delta
	rotation_degrees.y = o_rot_y + sin(t) * 8
