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
	main.call(&"_process", 65.0)
	player.level = 3
	player.take_damage(10)

	var level_label: Label = panel.get_node("Overlay/PanelContainer/MarginContainer/VBoxContainer/LevelLabel") as Label
	var time_label: Label = panel.get_node_or_null("Overlay/PanelContainer/MarginContainer/VBoxContainer/TimeLabel") as Label
	_expect(paused, "death keeps the game tree paused")
	_expect(panel.visible, "death opens the game over panel")
	_expect_equal(panel.process_mode, Node.PROCESS_MODE_ALWAYS, "panel processes while paused")
	_expect_equal(level_label.text, "Nível alcançado: 3", "panel displays the reached level")
	_expect(time_label != null, "game over panel contains the final survival time")
	if time_label != null:
		_expect_equal(time_label.text, "Tempo sobrevivido: 01:05", "panel displays final survival time")

	var previous_scene_id: int = main.get_instance_id()
	var restart_button: Button = panel.get_node("Overlay/PanelContainer/MarginContainer/VBoxContainer/RestartButton") as Button
	restart_button.pressed.emit()
	await process_frame
	await process_frame

	_expect(not paused, "restart removes the game pause")
	var scene_was_replaced: bool = current_scene != null and current_scene.get_instance_id() != previous_scene_id
	_expect(scene_was_replaced, "restart replaces the previous scene")
	if scene_was_replaced:
		var new_flow: GameFlow = current_scene as GameFlow
		var new_player: Player = current_scene.get_node("Player") as Player
		_expect_equal(new_player.level, 1, "restart resets level")
		_expect_equal(new_player.experience, 0, "restart resets experience")
		_expect_equal(new_player.current_health, 10, "restart restores health")
		_expect_equal(new_player.get_node("LancetWeapon").get("damage"), 1, "restart resets weapon damage")
		_expect_equal(new_flow.survival_seconds, 0, "restart resets survival time")
		var new_spawner: EnemySpawner = current_scene.get_node("EnemySpawner") as EnemySpawner
		_expect_equal(new_spawner.difficulty_level, 1, "restart resets threat level")
		_expect_equal(new_spawner.max_enemies, 10, "restart resets enemy cap")
		_expect_float(new_spawner.get_node("Timer").get("wait_time"), 2.0, "restart resets spawn interval")
		var new_hud: HUD = current_scene.get_node("HUD") as HUD
		_expect_equal(new_hud.get_node("SurvivalTimeLabel").get("text"), "Tempo: 00:00", "restarted HUD displays zero time")
		_expect_equal(new_hud.get_node("ThreatLevelLabel").get("text"), "Ameaça: I", "restarted HUD displays threat I")

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


func _expect_float(actual: float, expected: float, message: String) -> void:
	if is_equal_approx(actual, expected):
		return
	_failures += 1
	push_error("%s — expected %s, got %s" % [message, expected, actual])
