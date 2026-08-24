extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_test.call_deferred()


func _run_test() -> void:
	var main: Node2D = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var panel: CanvasLayer = main.get_node_or_null("GameOverPanel") as CanvasLayer
	_expect(panel != null, "main scene contains the game over panel")
	if panel == null:
		_cleanup(main)
		_finish()
		return

	_expect(not panel.visible, "game over panel starts hidden")
	var player: Player = main.get_node("Player") as Player
	player.level = 3
	player.take_damage(10)

	var level_label: Label = panel.get_node("Overlay/PanelContainer/MarginContainer/VBoxContainer/LevelLabel") as Label
	_expect(paused, "death keeps the game tree paused")
	_expect(panel.visible, "death opens the game over panel")
	_expect_equal(panel.process_mode, Node.PROCESS_MODE_ALWAYS, "panel processes while paused")
	_expect_equal(level_label.text, "Nível alcançado: 3", "panel displays the reached level")

	var previous_scene_id: int = main.get_instance_id()
	var restart_button: Button = panel.get_node("Overlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton") as Button
	restart_button.pressed.emit()
	await process_frame
	await process_frame

	_expect(not paused, "restart removes the game pause")
	var scene_was_replaced: bool = current_scene != null and current_scene.get_instance_id() != previous_scene_id
	_expect(scene_was_replaced, "restart replaces the previous scene")
	if scene_was_replaced:
		var new_player: Player = current_scene.get_node("Player") as Player
		_expect_equal(new_player.level, 1, "restart resets level")
		_expect_equal(new_player.experience, 0, "restart resets experience")
		_expect_equal(new_player.current_health, 10, "restart restores health")
		_expect_equal(new_player.get_node("LancetWeapon").get("damage"), 1, "restart resets weapon damage")

	_cleanup(current_scene if current_scene != null else main)
	_finish()


func _cleanup(main: Node) -> void:
	paused = false
	current_scene = null
	if is_instance_valid(main):
		main.free()


func _finish() -> void:
	if _failures == 0:
		print("GAME_OVER_PANEL_TESTS_PASSED")
		quit(0)
		return

	push_error("GAME_OVER_PANEL_TESTS_FAILED: %d" % _failures)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	push_error("%s — expected %s, got %s" % [message, expected, actual])
