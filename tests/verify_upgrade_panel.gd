extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	if not ResourceLoader.exists("res://scenes/upgrade_panel.tscn"):
		_expect(false, "upgrade panel scene exists")
		_finish()
		return

	await _test_multiple_levels_require_multiple_upgrades()
	await _test_panel_restores_preexisting_pause()
	_finish()


func _test_multiple_levels_require_multiple_upgrades() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	current_scene = world

	var player: Player = preload("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	var panel: CanvasLayer = load("res://scenes/upgrade_panel.tscn").instantiate()
	world.add_child(panel)
	await process_frame

	player.leveled_up.emit(2)
	player.leveled_up.emit(3)

	var button: Button = panel.get_node("Overlay/PanelContainer/MarginContainer/VBoxContainer/DamageButton")
	_expect(panel.visible, "panel opens when the player gains a level")
	_expect_equal(panel.get("pending_upgrades"), 2, "each gained level queues one upgrade")
	_expect(paused, "game pauses while an upgrade is pending")
	_expect_equal(button.text, "Dano da Lanceta: 1 → 2", "button shows current and next damage")

	button.pressed.emit()
	_expect_equal(player.get_node("LancetWeapon").get("damage"), 2, "first choice increases damage once")
	_expect_equal(panel.get("pending_upgrades"), 1, "first choice consumes one queued upgrade")
	_expect_equal(button.text, "Dano da Lanceta: 2 → 3", "button refreshes for the next queued upgrade")
	_expect(paused, "game remains paused while another upgrade is pending")

	button.pressed.emit()
	_expect_equal(player.get_node("LancetWeapon").get("damage"), 3, "second choice applies the second upgrade")
	_expect_equal(panel.get("pending_upgrades"), 0, "all queued upgrades are consumed")
	_expect(not panel.visible, "panel closes after the final choice")
	_expect(not paused, "game resumes after the final choice")

	current_scene = null
	world.free()


func _test_panel_restores_preexisting_pause() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	current_scene = world

	var player: Player = preload("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	var panel: CanvasLayer = load("res://scenes/upgrade_panel.tscn").instantiate()
	world.add_child(panel)
	await process_frame

	paused = true
	player.leveled_up.emit(2)
	var button: Button = panel.get_node("Overlay/PanelContainer/MarginContainer/VBoxContainer/DamageButton")
	button.pressed.emit()
	_expect(paused, "panel preserves a pause that existed before opening")

	paused = false
	current_scene = null
	world.free()


func _finish() -> void:
	if _failures == 0:
		print("UPGRADE_PANEL_TESTS_PASSED")
		quit(0)
		return

	push_error("UPGRADE_PANEL_TESTS_FAILED: %d" % _failures)
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
