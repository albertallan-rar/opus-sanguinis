class_name HUD
extends CanvasLayer

@onready var _experience_label: Label = $ExperienceLabel


func _ready() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return

	player.connect(&"experience_changed", _on_experience_changed)
	_on_experience_changed(player.get("experience"))


func _on_experience_changed(current_experience: int) -> void:
	_experience_label.text = "XP: %d" % current_experience
