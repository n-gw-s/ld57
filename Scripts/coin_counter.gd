extends Control

@export var AlphaSpeed: float = 5.0

@onready var label: Label = $Label

var alpha_dir: float = 1.0
var t: float

func _process(delta: float) -> void:
	t = clamp(t + delta * alpha_dir * AlphaSpeed, 0.0, 1.0)
	label.modulate.a = lerp(0.0, 1.0, t)

	if t >= 1.0 && alpha_dir > 0:
		alpha_dir = -1.0
	elif t <= 0 && alpha_dir < 0:
		queue_free()
