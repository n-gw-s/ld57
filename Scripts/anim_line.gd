extends GPUParticles3D

func play() -> void:
	restart()
	((draw_pass_1 as QuadMesh).material.albedo_texture as AnimatedTexture).current_frame = 0
