extends Sprite3D

@export var BeginAttractDistance: float = 5.0
@export var AttractSpeed: float = 1.0

@onready var area: Area3D = $Area3D

var attracting: bool

func _ready() -> void:
	area.connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.inc_coins()
		queue_free()

func _physics_process(_delta: float) -> void:
	var p: Player = %Player
	if p.global_position.distance_to(global_position) < BeginAttractDistance && !attracting:
		attracting = true
	if attracting:
		var to: Vector3 = (p.global_position - global_position).normalized() * AttractSpeed
		global_position += to
