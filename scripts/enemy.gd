class_name Enemy
extends CharacterBody2D

@export var speed: float = 120.0
@export var max_health: int = 3
@export var separation_radius: float = 48.0
@export var separation_weight: float = 1.5

var _target: Node2D
@onready var _current_health: int = max_health


func _ready() -> void:
	_target = get_tree().get_first_node_in_group(&"player") as Node2D


func take_damage(amount: int) -> void:
	_current_health -= amount

	if _current_health <= 0:
		queue_free()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return

	var pursuit_direction: Vector2 = global_position.direction_to(_target.global_position)
	var separation_direction: Vector2 = _calculate_separation()
	var movement_direction: Vector2 = (
		pursuit_direction + separation_direction * separation_weight
	).normalized()

	velocity = movement_direction * speed
	move_and_slide()


func _calculate_separation() -> Vector2:
	var separation: Vector2 = Vector2.ZERO

	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var other_enemy: Node2D = node as Node2D
		if other_enemy == null or other_enemy == self:
			continue

		var offset: Vector2 = global_position - other_enemy.global_position
		var distance: float = offset.length()
		if distance >= separation_radius:
			continue
		if is_zero_approx(distance):
			separation += (
				Vector2.LEFT
				if get_instance_id() < other_enemy.get_instance_id()
				else Vector2.RIGHT
			)
			continue

		var proximity: float = 1.0 - distance / separation_radius
		separation += offset.normalized() * proximity

	return separation.limit_length(1.0)
