class_name GameFlow
extends Node2D

signal survival_time_changed(total_seconds: int)

var survival_seconds: int = 0
var _elapsed_time: float = 0.0

@onready var _player: Player = $Player


func _ready() -> void:
	_player.died.connect(_on_player_died)


func _on_player_died() -> void:
	get_tree().paused = true


func _process(delta: float) -> void:
	if delta <= 0.0:
		return

	_elapsed_time += delta
	var completed_seconds: int = floori(_elapsed_time)
	if completed_seconds == survival_seconds:
		return

	survival_seconds = completed_seconds
	survival_time_changed.emit(survival_seconds)
