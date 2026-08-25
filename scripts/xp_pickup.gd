class_name XPPickup
extends Area2D

@export var value: int = 1

@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	_apply_visual_identity()


func configure(new_value: int) -> void:
	value = clampi(new_value, 1, 3)
	if is_node_ready():
		_apply_visual_identity()


func _apply_visual_identity() -> void:
	match value:
		2:
			_visual.color = Color(1.0, 0.82, 0.2, 1.0)
			_visual.scale = Vector2.ONE * 1.25
		3:
			_visual.color = Color(0.3, 1.0, 0.45, 1.0)
			_visual.scale = Vector2.ONE * 1.5
		_:
			_visual.color = Color(0.35, 0.85, 0.95, 1.0)
			_visual.scale = Vector2.ONE


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method(&"gain_experience"):
		return

	body.call(&"gain_experience", value)
	queue_free()
