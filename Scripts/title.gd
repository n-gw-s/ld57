extends Control

var t: float = 0.0
var introing: bool = false

func intro() -> void:
	if introing:
		return

	introing = true
	t = 0.0
	get_node("Background/Title").visible = false
	get_node("Background/Confirm").visible = false

func start() -> void:
	get_tree().paused = false
	visible = false
	get_node("/root/Main/Sandbox/Player").viewport_container.visible = true
	get_node("/root/Main/Sandbox/Player").cam.make_current()

func _ready() -> void:
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		intro()

func _process(delta: float) -> void:

	if !introing:
		t = clamp(t + delta * 4.0, 0.0, 1.0)
		var confirm: Label = get_node("Background/Confirm")
		if t >= 1.0:
			confirm.visible = !confirm.visible
			t = 0.0
	else:
		t = clamp(t + delta * 0.5, 0.0, 1.0)
		get_node("Background/Intro").self_modulate.a = t

		if t >= 1.0:
			start()
