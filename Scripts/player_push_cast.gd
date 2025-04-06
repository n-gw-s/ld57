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
			var xz_kb: Vector3 = obj.knockback
			if xz_kb.length() <= KB_LENGTH_MIN:
				var v: Vector3 = -get_collision_normal(i) * Force
				obj.knockback.x += v.x
				obj.knockback.z += v.z
