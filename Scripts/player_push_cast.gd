extends ShapeCast3D

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
			var v: Vector3 = -get_collision_normal(i) * Force
			obj.knockback.x += v.x
			obj.knockback.z += v.z
			Utils.gen_sound(obj.SelfPushSound, obj, Vector2(0.8, 1.2))
			obj.shake_cam(v.length())
