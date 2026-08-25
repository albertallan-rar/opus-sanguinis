class_name EnemySpawner
extends Node

signal difficulty_changed(level: int)

const MAX_DIFFICULTY_LEVEL: int = 10
const SPAWN_INTERVALS: Array[float] = [2.0, 1.8, 1.6, 1.4, 1.2, 1.0, 0.9, 0.8, 0.7, 0.6]
const BASE_MAX_ENEMIES: int = 10
const MAX_ENEMIES_PER_LEVEL: int = 2

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 700.0
@export var max_enemies: int = 10

var difficulty_level: int = 1
var _target: Node2D

@onready var _spawn_timer: Timer = $Timer


func _ready() -> void:
	_target = get_tree().get_first_node_in_group(&"player") as Node2D
	_apply_difficulty_settings()

	var game_flow: GameFlow = get_parent() as GameFlow
	if game_flow != null:
		game_flow.survival_time_changed.connect(_on_survival_time_changed)


func _on_survival_time_changed(total_seconds: int) -> void:
	var new_level: int = clampi(total_seconds / 60 + 1, 1, MAX_DIFFICULTY_LEVEL)

	if new_level <= difficulty_level:
		return

	difficulty_level = new_level
	_apply_difficulty_settings()
	difficulty_changed.emit(difficulty_level)


func _apply_difficulty_settings() -> void:
	_spawn_timer.wait_time = SPAWN_INTERVALS[difficulty_level - 1]
	max_enemies = BASE_MAX_ENEMIES + (difficulty_level - 1) * MAX_ENEMIES_PER_LEVEL


func _on_timer_timeout() -> void:
	if not is_instance_valid(_target) or enemy_scene == null:
		return
	if get_tree().get_nodes_in_group(&"enemies").size() >= max_enemies:
		return

	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	if enemy == null:
		return

	enemy.max_health = difficulty_level + 2
	if difficulty_level >= 10:
		enemy.speed = 160.0
		enemy.contact_damage = 3
	elif difficulty_level >= 5:
		enemy.speed = 140.0
		enemy.contact_damage = 2

	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	get_parent().add_child(enemy)
	enemy.global_position = _target.global_position + direction * spawn_radius
