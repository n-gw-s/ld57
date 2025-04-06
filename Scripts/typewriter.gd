class_name Typewriter
extends Label3D

@export var Say: String = ""
@export var LetterSpeed: float = 0.125
@export var FadeSpeed: float = 1.0

var current: int = -1
var t: float

func add_letter() -> void:
	if is_typed():
		return
	
	current = clamp(current + 1, 0, Say.length() - 1)
	text += Say[current]

func is_typed() -> bool:
	return current == Say.length() - 1

func is_done() -> bool:
	return modulate.a <= 0

func reset() -> void:
	current = -1
	text = ""
	t = 0
	modulate.a = 1.0

func _process(delta: float) -> void:
	t = clamp(t + delta / LetterSpeed, 0.0, 1.0)

	if t >= 1.0:
		if !is_typed():
			add_letter()
			t = 0.0
		else:
			modulate.a = clamp(modulate.a - delta * FadeSpeed, 0.0, 1.0)
