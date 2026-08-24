class_name XPPickup
extends Area2D

@export var value: int = 1


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method(&"gain_experience"):
		return

	body.call(&"gain_experience", value)
	queue_free()
