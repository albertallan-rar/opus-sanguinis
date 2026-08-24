extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_test.call_deferred()


func _run_test() -> void:
	var main: Node2D = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var player: Player = main.get_node("Player") as Player
	player.take_damage(10)

	if paused:
		print("GAME_FLOW_TESTS_PASSED")
		paused = false
		current_scene = null
		main.free()
		quit(0)
		return

	push_error("player death pauses the entire game tree")
	paused = false
	current_scene = null
	main.free()
	push_error("GAME_FLOW_TESTS_FAILED: 1")
	quit(1)
