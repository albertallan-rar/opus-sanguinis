class_name GameOverPanel
extends CanvasLayer

var _player: Player
var _game_flow: GameFlow

@onready var _level_label: Label = $Overlay/PanelContainer/MarginContainer/VBoxContainer/LevelLabel
@onready var _time_label: Label = $Overlay/PanelContainer/MarginContainer/VBoxContainer/TimeLabel
@onready var _restart_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton


func _ready() -> void:
	visible = false
	_game_flow = get_parent() as GameFlow
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		return

	_player.died.connect(_on_player_died)
	_restart_button.pressed.connect(_on_restart_button_pressed)


func _on_player_died() -> void:
	_level_label.text = "Nível alcançado: %d" % _player.level
	if _game_flow != null:
		_time_label.text = "Tempo sobrevivido: %s" % _format_time(_game_flow.survival_seconds)
	visible = true


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	var error: Error = get_tree().reload_current_scene()
	if error == OK:
		return

	get_tree().paused = true
	push_error("Falha ao reiniciar a partida: código %d" % error)


func _format_time(total_seconds: int) -> String:
	var minutes: int = floori(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
