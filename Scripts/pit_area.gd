extends Area3D

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is NPC:
		body.queue_free()
		Utils.npcs_damned = clamp(Utils.npcs_damned + 1, 0, INF)
