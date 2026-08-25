class_name HUD
extends CanvasLayer

var _game_flow: GameFlow
var _enemy_spawner: EnemySpawner

@onready var _experience_label: Label = $ExperienceLabel
@onready var _level_label: Label = $LevelLabel
@onready var _lancet_damage_label: Label = $LancetDamageLabel
@onready var _lancet_interval_label: Label = $LancetIntervalLabel
@onready var _health_label: Label = $HealthLabel
@onready var _survival_time_label: Label = $SurvivalTimeLabel
@onready var _threat_level_label: Label = $ThreatLevelLabel


func _ready() -> void:
	_game_flow = get_parent() as GameFlow
	if _game_flow != null:
		_game_flow.survival_time_changed.connect(_on_survival_time_changed)
		_on_survival_time_changed(_game_flow.survival_seconds)

	_enemy_spawner = get_parent().get_node_or_null("EnemySpawner") as EnemySpawner
	if _enemy_spawner != null:
		_enemy_spawner.difficulty_changed.connect(_on_difficulty_changed)
		_on_difficulty_changed(_enemy_spawner.difficulty_level)

	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return

	player.connect(&"experience_changed", _on_experience_changed)
	player.connect(&"leveled_up", _on_leveled_up)
	player.connect(&"health_changed", _on_health_changed)
	_on_experience_changed(player.get("experience"), player.get("experience_required"))
	_on_leveled_up(player.get("level"))
	_on_health_changed(player.get("current_health"), player.get("max_health"))

	var weapon: LancetWeapon = player.get_node("LancetWeapon") as LancetWeapon
	weapon.damage_changed.connect(_on_lancet_damage_changed)
	weapon.attack_interval_changed.connect(_on_lancet_interval_changed)
	_on_lancet_damage_changed(weapon.damage)
	_on_lancet_interval_changed(weapon.attack_interval)


func _on_experience_changed(current_experience: int, required_experience: int) -> void:
	_experience_label.text = "XP: %d / %d" % [current_experience, required_experience]


func _on_leveled_up(new_level: int) -> void:
	_level_label.text = "Level: %d" % new_level


func _on_lancet_damage_changed(current_damage: int) -> void:
	_lancet_damage_label.text = "Dano da Lanceta: %d" % current_damage


func _on_lancet_interval_changed(current_interval: float) -> void:
	var formatted: String = ("%.2f" % current_interval).replace(".", ",")
	_lancet_interval_label.text = "Intervalo da Lanceta: %ss" % formatted


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	_health_label.text = "Vida: %d / %d" % [current_health, maximum_health]


func _on_survival_time_changed(total_seconds: int) -> void:
	var minutes: int = floori(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	_survival_time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]


func _on_difficulty_changed(level: int) -> void:
	var roman_level: String = ["I", "II", "III"][clampi(level, 1, 3) - 1]
	_threat_level_label.text = "Ameaça: %s" % roman_level
