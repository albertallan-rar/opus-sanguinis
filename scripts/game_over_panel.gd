class_name GameOverPanel
extends CanvasLayer

var _player: Player

@onready var _level_label: Label = $Overlay/PanelContainer/MarginContainer/VBoxContainer/LevelLabel
@onready var _restart_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton


func _ready() -> void:
	visible = false
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		return

	_player.died.connect(_on_player_died)
	_restart_button.pressed.connect(_on_restart_button_pressed)


func _on_player_died() -> void:
	_level_label.text = "Nível alcançado: %d" % _player.level
	visible = true


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	var error: Error = get_tree().reload_current_scene()
	if error == OK:
		return

	get_tree().paused = true
	push_error("Falha ao reiniciar a partida: código %d" % error)
