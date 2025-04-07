extends Area3D

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		get_node("/root/Main/").add_child(preload("res://Scenes/win_screen.tscn").instantiate())
		get_tree().paused = true
