class_name EnemySpawner
extends Node

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 700.0
@export var max_enemies: int = 10

var _target: Node2D


func _ready() -> void:
	_target = get_tree().get_first_node_in_group(&"player") as Node2D


func _on_timer_timeout() -> void:
	if not is_instance_valid(_target) or enemy_scene == null:
		return
	if get_tree().get_nodes_in_group(&"enemies").size() >= max_enemies:
		return

	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	get_parent().add_child(enemy)
	enemy.global_position = _target.global_position + direction * spawn_radius
