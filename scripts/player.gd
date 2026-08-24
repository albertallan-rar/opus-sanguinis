class_name Player
extends CharacterBody2D

signal experience_changed(current_experience: int, required_experience: int)
signal leveled_up(new_level: int)

@export var speed: float = 240.0
@export var experience_required: int = 5

var experience: int = 0
var level: int = 1


func gain_experience(amount: int) -> void:
	experience += amount

	while experience >= experience_required:
		experience -= experience_required
		level += 1
		leveled_up.emit(level)

	experience_changed.emit(experience, experience_required)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()
