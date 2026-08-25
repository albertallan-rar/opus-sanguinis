class_name EnemySpawner
extends Node

signal difficulty_changed(level: int)

const STAGE_TWO_TIME: int = 60
const STAGE_THREE_TIME: int = 120
const STAGE_ONE_INTERVAL: float = 2.0
const STAGE_TWO_INTERVAL: float = 1.5
const STAGE_THREE_INTERVAL: float = 1.0
const STAGE_ONE_MAX_ENEMIES: int = 10
const STAGE_TWO_MAX_ENEMIES: int = 15
const STAGE_THREE_MAX_ENEMIES: int = 20

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 700.0
@export var max_enemies: int = 10

var difficulty_level: int = 1
var _target: Node2D

@onready var _spawn_timer: Timer = $Timer


func _ready() -> void:
	_target = get_tree().get_first_node_in_group(&"player") as Node2D
	_spawn_timer.wait_time = STAGE_ONE_INTERVAL
	max_enemies = STAGE_ONE_MAX_ENEMIES

	var game_flow: GameFlow = get_parent() as GameFlow
	if game_flow != null:
		game_flow.survival_time_changed.connect(_on_survival_time_changed)


func _on_survival_time_changed(total_seconds: int) -> void:
	var new_level: int = 1
	if total_seconds >= STAGE_THREE_TIME:
		new_level = 3
	elif total_seconds >= STAGE_TWO_TIME:
		new_level = 2

	if new_level <= difficulty_level:
		return

	difficulty_level = new_level
	match difficulty_level:
		2:
			_spawn_timer.wait_time = STAGE_TWO_INTERVAL
			max_enemies = STAGE_TWO_MAX_ENEMIES
		3:
			_spawn_timer.wait_time = STAGE_THREE_INTERVAL
			max_enemies = STAGE_THREE_MAX_ENEMIES

	difficulty_changed.emit(difficulty_level)


func _on_timer_timeout() -> void:
	if not is_instance_valid(_target) or enemy_scene == null:
		return
	if get_tree().get_nodes_in_group(&"enemies").size() >= max_enemies:
		return

	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	get_parent().add_child(enemy)
	enemy.global_position = _target.global_position + direction * spawn_radius
