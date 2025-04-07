extends Control

@onready var label: Label = $Background/Label
@onready var coins_label: Label = $Background/LabelCoins
@onready var npcs_label: Label = $Background/LabelNPCs

var t: float

func _ready() -> void:
	label.self_modulate.a = 0
	coins_label.self_modulate.a = 0
	npcs_label.self_modulate.a = 0

func _process(delta: float) -> void:
	t = clamp(t + delta * 0.33, 0.0, 1.0)

	label.self_modulate.a = t

	if t >= 1.0:
		coins_label.self_modulate.a = 1.0
		npcs_label.self_modulate.a = 1.0

		var coins: int = get_node("/root/Main/Sandbox/Player").coins
		var coins_per: float = float(coins) / float(Utils.total_coins) * 100
		coins_label.text = "Coins Collected: " + str(int(round(coins_per))) + "% (" + str(coins) + "/" + str(Utils.total_coins) + ")"

		var damned: int = Utils.npcs_damned
		var damned_per: float = float(damned) / float(Utils.total_npcs) * 100
		npcs_label.text = "NPCs Damned: " + str(int(round(damned_per))) + "% (" + str(damned) + "/" + str(Utils.total_npcs) + ")"

		if Input.is_action_just_pressed("Pause"):
			get_tree().quit()
