class_name Lancet
extends Area2D

@export var speed: float = 500.0
@export var max_range: float = 600.0
@export var damage: int = 1

var _direction: Vector2 = Vector2.RIGHT
var _distance_traveled: float = 0.0


func launch(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	var movement: Vector2 = _direction * speed * delta
	global_position += movement
	_distance_traveled += movement.length()

	if _distance_traveled >= max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"take_damage"):
		body.call(&"take_damage", damage)

	queue_free()
