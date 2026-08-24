class_name UpgradePanel
extends CanvasLayer

var pending_upgrades: int = 0
var _was_tree_paused: bool = false
var _weapon: LancetWeapon

@onready var _damage_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/DamageButton


func _ready() -> void:
	visible = false
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return

	_weapon = player.get_node("LancetWeapon") as LancetWeapon
	player.connect(&"leveled_up", _on_player_leveled_up)
	_damage_button.pressed.connect(_on_damage_button_pressed)


func _on_player_leveled_up(_new_level: int) -> void:
	if pending_upgrades == 0:
		_was_tree_paused = get_tree().paused

	pending_upgrades += 1
	visible = true
	_refresh_button()
	get_tree().paused = true


func _on_damage_button_pressed() -> void:
	if pending_upgrades <= 0 or _weapon == null:
		return

	_weapon.increase_damage()
	pending_upgrades -= 1

	if pending_upgrades > 0:
		_refresh_button()
		return

	visible = false
	get_tree().paused = _was_tree_paused


func _refresh_button() -> void:
	_damage_button.text = "Dano da Lanceta: %d → %d" % [_weapon.damage, _weapon.damage + 1]
