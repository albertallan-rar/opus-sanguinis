extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	_test_survival_time_accumulates_complete_seconds()
	await _test_player_death_pauses_tree()
	_finish()


func _test_survival_time_accumulates_complete_seconds() -> void:
	var flow: GameFlow = GameFlow.new()
	var events: Array[int] = []

	_expect(flow.has_signal(&"survival_time_changed"), "game flow exposes survival_time_changed")
	_expect(flow.has_method(&"_process"), "game flow processes survival time")
	_expect_equal(flow.get("survival_seconds"), 0, "survival time starts at zero")
	if not flow.has_signal(&"survival_time_changed") or not flow.has_method(&"_process"):
		flow.free()
		return

	flow.connect(&"survival_time_changed", func(value: int) -> void: events.append(value))
	flow.call(&"_process", 0.4)
	_expect_equal(flow.get("survival_seconds"), 0, "fractional time does not complete a second")
	flow.call(&"_process", 0.6)
	_expect_equal(flow.get("survival_seconds"), 1, "fractions accumulate into a complete second")
	_expect_equal(events, [1], "first completed second emits once")

	flow.call(&"_process", 0.25)
	_expect_equal(events, [1], "same displayed second emits no event")
	flow.call(&"_process", 3.0)
	_expect_equal(flow.get("survival_seconds"), 4, "large delta advances directly to final second")
	_expect_equal(events, [1, 4], "large delta emits one final value")

	flow.call(&"_process", 0.0)
	flow.call(&"_process", -1.0)
	_expect_equal(flow.get("survival_seconds"), 4, "non-positive delta is ignored")
	_expect_equal(events, [1, 4], "ignored delta emits no event")
	flow.free()


func _test_player_death_pauses_tree() -> void:
	var main: Node2D = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var player: Player = main.get_node("Player") as Player
	player.take_damage(10)
	_expect(paused, "player death pauses the entire game tree")

	paused = false
	current_scene = null
	main.free()


func _finish() -> void:
	if _failures == 0:
		print("GAME_FLOW_TESTS_PASSED")
		quit(0)
		return

	push_error("GAME_FLOW_TESTS_FAILED: %d" % _failures)
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
