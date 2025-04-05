extends Node

@export var InitialScene: PackedScene

func _enter_tree() -> void:
	var scn: Node = InitialScene.instantiate()
	add_child(scn)
