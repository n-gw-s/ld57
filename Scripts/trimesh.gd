@tool
extends MeshInstance3D

@export_tool_button("Generate", "Generate") var btn = gen

func gen() -> void:
    for i in get_children():
        if i is StaticBody3D:
            i.free()
    create_trimesh_collision()