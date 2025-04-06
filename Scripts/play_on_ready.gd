extends AnimatedSprite3D

@export var AnimationName: String = "default"

func _ready() -> void:
    play(AnimationName)