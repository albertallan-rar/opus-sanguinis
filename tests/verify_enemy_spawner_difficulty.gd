extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_stage_boundaries_apply_once()
	await _test_large_time_jump_applies_only_final_stage()
	_finish()


func _test_stage_boundaries_apply_once() -> void:
	var flow: GameFlow = GameFlow.new()
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	var spawner: EnemySpawner = preload("res://scenes/enemy_spawner.tscn").instantiate()
	flow.add_child(player)
	flow.add_child(spawner)
	root.add_child(flow)
	await process_frame

	var timer: Timer = spawner.get_node("Timer") as Timer
	var events: Array[int] = []
	_expect(spawner.has_signal(&"difficulty_changed"), "spawner exposes difficulty_changed")
	_expect(spawner.has_method(&"_on_survival_time_changed"), "spawner handles survival time changes")
	_expect_equal(spawner.get("difficulty_level"), 1, "spawner starts at threat I")
	_expect_float(timer.wait_time, 2.0, "threat I starts with two-second interval")
	_expect_equal(spawner.max_enemies, 10, "threat I starts with ten-enemy cap")
	if not spawner.has_signal(&"difficulty_changed") or not spawner.has_method(&"_on_survival_time_changed"):
		flow.free()
		return

	spawner.connect(&"difficulty_changed", func(level: int) -> void: events.append(level))
	flow._process(59.0)
	_expect_equal(spawner.get("difficulty_level"), 1, "59 seconds remains at threat I")
	_expect_equal(events, [], "threat I emits no transition")

	flow._process(1.0)
	_expect_equal(spawner.get("difficulty_level"), 2, "60 seconds activates threat II")
	_expect_float(timer.wait_time, 1.5, "threat II reduces spawn interval")
	_expect_equal(spawner.max_enemies, 15, "threat II raises enemy cap")

	flow._process(59.0)
	_expect_equal(spawner.get("difficulty_level"), 2, "119 seconds remains at threat II")
	flow._process(1.0)
	_expect_equal(spawner.get("difficulty_level"), 3, "120 seconds activates threat III")
	_expect_float(timer.wait_time, 1.0, "threat III reduces interval to one second")
	_expect_equal(spawner.max_enemies, 20, "threat III raises enemy cap")
	_expect_equal(events, [2, 3], "each stage transition emits once")
	flow.free()


func _test_large_time_jump_applies_only_final_stage() -> void:
	var flow: GameFlow = GameFlow.new()
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	var spawner: EnemySpawner = preload("res://scenes/enemy_spawner.tscn").instantiate()
	flow.add_child(player)
	flow.add_child(spawner)
	root.add_child(flow)
	await process_frame

	if not spawner.has_signal(&"difficulty_changed"):
		flow.free()
		return

	var events: Array[int] = []
	spawner.connect(&"difficulty_changed", func(level: int) -> void: events.append(level))
	flow._process(130.0)

	_expect_equal(spawner.get("difficulty_level"), 3, "large time jump applies threat III")
	_expect_equal(events, [3], "large time jump emits only the final stage")
	flow.free()


func _finish() -> void:
	if _failures == 0:
		print("ENEMY_SPAWNER_DIFFICULTY_TESTS_PASSED")
		quit(0)
		return

	push_error("ENEMY_SPAWNER_DIFFICULTY_TESTS_FAILED: %d" % _failures)
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
