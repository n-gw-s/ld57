extends Node

func gen_sound(stream: AudioStream, parent: Node3D, pitch_range: Vector2 = Vector2.ONE) -> void:
    if stream == null:
        return
    
    if parent == null:
        parent = get_node("/root/Main/Sandbox")
    
    var audio: AudioStreamPlayer3D = preload("res://Scenes/audio_stream.tscn").instantiate()
    audio.stream = stream
    audio.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
    parent.add_child(audio)