extends Node

@export var InitialScene: PackedScene

func _ready() -> void:
	var scn: Node = InitialScene.instantiate()
	add_child(scn)
