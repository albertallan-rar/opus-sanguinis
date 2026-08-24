class_name LancetWeapon
extends Node2D

@export var lancet_scene: PackedScene
@export var attack_range: float = 600.0


func _on_attack_timer_timeout() -> void:
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return

	var distance: float = global_position.distance_to(target.global_position)
	if distance > attack_range:
		return

	var lancet: Area2D = lancet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(lancet)
	lancet.global_position = global_position
	lancet.call("launch", global_position.direction_to(target.global_position))


func _find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance: float = INF

	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy: Node2D = node as Node2D
		if enemy == null:
			continue

		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	return nearest_enemy
