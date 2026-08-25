extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_stage_drop_boundaries()
	await _test_pickup_value_controls_visual_identity()
	await _test_spawner_propagates_stage_to_enemy()
	_finish()


func _test_stage_drop_boundaries() -> void:
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	root.add_child(enemy)
	await process_frame

	_expect(enemy.has_method(&"get_xp_value_for_roll"), "enemy exposes deterministic XP drop selection")
	if enemy.has_method(&"get_xp_value_for_roll"):
		enemy.set("xp_drop_stage", 4)
		_expect_equal(enemy.call(&"get_xp_value_for_roll", 0.99), 1, "threat IV drops only blue XP")
		enemy.set("xp_drop_stage", 5)
		_expect_equal(enemy.call(&"get_xp_value_for_roll", 0.69), 1, "threat V keeps blue below seventy percent")
		_expect_equal(enemy.call(&"get_xp_value_for_roll", 0.70), 2, "threat V unlocks yellow at thirty percent")
		enemy.set("xp_drop_stage", 10)
		_expect_equal(enemy.call(&"get_xp_value_for_roll", 0.49), 1, "threat X keeps blue at fifty percent")
		_expect_equal(enemy.call(&"get_xp_value_for_roll", 0.50), 2, "threat X selects yellow after blue")
		_expect_equal(enemy.call(&"get_xp_value_for_roll", 0.84), 2, "threat X keeps yellow at thirty-five percent")
		_expect_equal(enemy.call(&"get_xp_value_for_roll", 0.85), 3, "threat X unlocks green at fifteen percent")
	enemy.free()


func _test_pickup_value_controls_visual_identity() -> void:
	var pickup: XPPickup = preload("res://scenes/xp_pickup.tscn").instantiate()
	root.add_child(pickup)
	await process_frame

	var visual: Polygon2D = pickup.get_node("Visual") as Polygon2D
	_expect(pickup.has_method(&"configure"), "XP pickup can be configured from its awarded value")
	if pickup.has_method(&"configure"):
		pickup.call(&"configure", 1)
		_expect_equal(pickup.value, 1, "blue pickup awards one XP")
		_expect_equal(visual.color, Color(0.35, 0.85, 0.95, 1.0), "one-XP pickup is blue")
		_expect_equal(visual.scale, Vector2.ONE, "one-XP pickup uses base size")
		pickup.call(&"configure", 2)
		_expect_equal(pickup.value, 2, "yellow pickup awards two XP")
		_expect_equal(visual.color, Color(1.0, 0.82, 0.2, 1.0), "two-XP pickup is yellow")
		_expect_equal(visual.scale, Vector2.ONE * 1.25, "two-XP pickup is larger")
		pickup.call(&"configure", 3)
		_expect_equal(pickup.value, 3, "green pickup awards three XP")
		_expect_equal(visual.color, Color(0.3, 1.0, 0.45, 1.0), "three-XP pickup is green")
		_expect_equal(visual.scale, Vector2.ONE * 1.5, "three-XP pickup is largest")
	pickup.free()


func _test_spawner_propagates_stage_to_enemy() -> void:
	var flow: GameFlow = GameFlow.new()
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	var spawner: EnemySpawner = preload("res://scenes/enemy_spawner.tscn").instantiate()
	flow.add_child(player)
	flow.add_child(spawner)
	root.add_child(flow)
	await process_frame

	spawner.call(&"_on_survival_time_changed", 240)
	spawner.call(&"_on_timer_timeout")
	await process_frame
	var enemies: Array[Node] = get_nodes_in_group(&"enemies")
	_expect_equal(enemies.size(), 1, "threat V spawns one enemy for XP stage validation")
	if enemies.size() == 1:
		_expect_equal(enemies[0].get("xp_drop_stage"), 5, "spawned enemy receives threat V drop table")
	flow.free()


func _finish() -> void:
	if _failures == 0:
		print("XP_DROP_TIERS_TESTS_PASSED")
		quit(0)
		return

	push_error("XP_DROP_TIERS_TESTS_FAILED: %d" % _failures)
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
