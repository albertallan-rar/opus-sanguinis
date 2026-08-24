class_name UpgradePanel
extends CanvasLayer

var pending_upgrades: int = 0
var _was_tree_paused: bool = false
var _weapon: LancetWeapon

@onready var _damage_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/DamageButton
@onready var _attack_speed_button: Button = $Overlay/PanelContainer/MarginContainer/VBoxContainer/AttackSpeedButton


func _ready() -> void:
	visible = false
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return

	_weapon = player.get_node("LancetWeapon") as LancetWeapon
	player.connect(&"leveled_up", _on_player_leveled_up)
	_damage_button.pressed.connect(_on_damage_button_pressed)
	_attack_speed_button.pressed.connect(_on_attack_speed_button_pressed)


func _on_player_leveled_up(_new_level: int) -> void:
	if pending_upgrades == 0:
		_was_tree_paused = get_tree().paused

	pending_upgrades += 1
	visible = true
	_refresh_buttons()
	get_tree().paused = true


func _on_damage_button_pressed() -> void:
	if pending_upgrades <= 0 or _weapon == null:
		return

	_weapon.increase_damage()
	_consume_upgrade()


func _on_attack_speed_button_pressed() -> void:
	if pending_upgrades <= 0 or _weapon == null:
		return
	if not _weapon.increase_attack_speed():
		return

	_consume_upgrade()


func _consume_upgrade() -> void:
	pending_upgrades -= 1

	if pending_upgrades > 0:
		_refresh_buttons()
		return

	visible = false
	get_tree().paused = _was_tree_paused


func _refresh_buttons() -> void:
	_damage_button.text = "Dano da Lanceta: %d → %d" % [_weapon.damage, _weapon.damage + 1]

	var at_minimum: bool = is_equal_approx(_weapon.attack_interval, _weapon.minimum_attack_interval)
	_attack_speed_button.disabled = at_minimum
	if at_minimum:
		_attack_speed_button.text = "Intervalo de ataque: %s (máximo)" % _format_seconds(_weapon.attack_interval)
		return

	_attack_speed_button.text = "Intervalo de ataque: %s → %s" % [
		_format_seconds(_weapon.attack_interval),
		_format_seconds(_weapon.get_next_attack_interval())
	]


func _format_seconds(value: float) -> String:
	return ("%.2f" % value).replace(".", ",") + "s"
