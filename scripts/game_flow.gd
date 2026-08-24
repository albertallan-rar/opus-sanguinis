class_name GameFlow
extends Node2D

@onready var _player: Player = $Player


func _ready() -> void:
	_player.died.connect(_on_player_died)


func _on_player_died() -> void:
	get_tree().paused = true
