extends ShapeCast3D

const KB_LENGTH_MIN: float = 0.1

@export var Force: float = 1.0

func _physics_process(_delta: float) -> void:
	if !enabled:
		return
		
	force_shapecast_update()
	force_update_transform()

	for i in get_collision_count():
		var obj: Object = get_collider(i)

		if !is_instance_valid(obj):
			continue
		
		if obj is Player:
			if obj.knockback.length() <= KB_LENGTH_MIN:
				obj.knockback += -get_collision_normal(i) * Force
	
