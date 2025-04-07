extends Node

var total_coins: int
var npcs_damned: int
var total_npcs: int
var frames_passed: int

func _physics_process(_delta: float) -> void:
    if frames_passed > 0:
        if total_coins == 0:
            total_coins = get_tree().get_node_count_in_group("Coin")
        if total_npcs == 0:
            total_npcs = get_tree().get_node_count_in_group("NPC")

    frames_passed += 1

func gen_sound(stream: AudioStream, parent: Node3D, pitch_range: Vector2 = Vector2.ONE) -> void:
    if stream == null:
        return
    
    if parent == null:
        parent = get_node("/root/Main/Sandbox")
    
    var audio: AudioStreamPlayer3D = preload("res://Scenes/audio_stream.tscn").instantiate()
    audio.stream = stream
    audio.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
    parent.add_child(audio)