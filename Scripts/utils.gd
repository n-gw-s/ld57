extends Node

func gen_sound(stream: AudioStream, p: Vector3, parent: Node3D = null) -> void:
    if parent == null:
        parent = get_node("/root/Main/Sandbox")
    
    var audio: AudioStreamPlayer3D = preload("res://Scenes/audio_stream.tscn").instantiate()
    audio.stream = stream
    parent.add_child(audio)
    audio.position = p