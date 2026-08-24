class_name HUD
extends CanvasLayer

@onready var _experience_label: Label = $ExperienceLabel
@onready var _level_label: Label = $LevelLabel
@onready var _lancet_damage_label: Label = $LancetDamageLabel


func _ready() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return

	player.connect(&"experience_changed", _on_experience_changed)
	player.connect(&"leveled_up", _on_leveled_up)
	_on_experience_changed(player.get("experience"), player.get("experience_required"))
	_on_leveled_up(player.get("level"))

	var weapon: LancetWeapon = player.get_node("LancetWeapon") as LancetWeapon
	weapon.damage_changed.connect(_on_lancet_damage_changed)
	_on_lancet_damage_changed(weapon.damage)


func _on_experience_changed(current_experience: int, required_experience: int) -> void:
	_experience_label.text = "XP: %d / %d" % [current_experience, required_experience]


func _on_leveled_up(new_level: int) -> void:
	_level_label.text = "Level: %d" % new_level


func _on_lancet_damage_changed(current_damage: int) -> void:
	_lancet_damage_label.text = "Dano da Lanceta: %d" % current_damage
