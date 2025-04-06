extends AnimatedSprite3D

@export var AnimationName: String = "default"
@export var AndFree: bool = false

func _ready() -> void:
	play(AnimationName)

	if AndFree:
		connect("animation_finished", _on_finished)

func _on_finished() -> void:
	queue_free()
