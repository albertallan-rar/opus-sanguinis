class_name Player
extends CharacterBody2D

signal experience_changed(current_experience: int, required_experience: int)
signal leveled_up(new_level: int)
signal health_changed(current_health: int, maximum_health: int)
signal died

@export var speed: float = 240.0
@export var experience_required: int = 5
@export var max_health: int = 10

var experience: int = 0
var level: int = 1
var current_health: int = max_health
var _is_dead: bool = false

@onready var _damage_indicator: Label = $DamageIndicator
@onready var _damage_indicator_timer: Timer = $DamageIndicatorTimer


func gain_experience(amount: int) -> void:
	experience += amount

	while experience >= experience_required:
		experience -= experience_required
		level += 1
		experience_required = 5 + (level - 1) * 2
		leveled_up.emit(level)

	experience_changed.emit(experience, experience_required)


func take_damage(amount: int) -> void:
	if amount <= 0 or _is_dead:
		return

	current_health = maxi(current_health - amount, 0)
	if _damage_indicator != null and _damage_indicator_timer != null:
		_damage_indicator.text = "-%d" % amount
		_damage_indicator.visible = true
		_damage_indicator_timer.start()
	health_changed.emit(current_health, max_health)
	if current_health > 0:
		return

	_is_dead = true
	velocity = Vector2.ZERO
	died.emit()


func _on_damage_indicator_timer_timeout() -> void:
	if _damage_indicator != null:
		_damage_indicator.visible = false


func _physics_process(_delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return

	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()
