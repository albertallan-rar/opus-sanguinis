class_name Player
extends CharacterBody2D

signal experience_changed(current_experience: int)

@export var speed: float = 240.0

var experience: int = 0


func gain_experience(amount: int) -> void:
	experience += amount
	experience_changed.emit(experience)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()
