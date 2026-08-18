class_name Enemy
extends CharacterBody2D

@export var speed: float = 120.0

var _target: Node2D


func _ready() -> void:
	_target = get_tree().get_first_node_in_group(&"player") as Node2D


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(_target.global_position) * speed
	move_and_slide()
