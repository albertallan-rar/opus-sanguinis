extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_experience_requirement_grows_per_level()
	await _test_enemy_health_indicator_tracks_damage()
	await _test_player_damage_indicator_shows_received_damage()
	_finish()


func _test_experience_requirement_grows_per_level() -> void:
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	await process_frame

	player.gain_experience(5)
	_expect_equal(player.level, 2, "five XP raises the player to level two")
	_expect_equal(player.experience_required, 7, "level two requires seven XP")
	player.gain_experience(16)
	_expect_equal(player.level, 4, "carried XP can grant multiple levels")
	_expect_equal(player.experience, 0, "successive requirements consume carried XP correctly")
	_expect_equal(player.experience_required, 11, "level four requires eleven XP")
	player.free()


func _test_enemy_health_indicator_tracks_damage() -> void:
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.max_health = 4
	root.add_child(enemy)
	await process_frame

	var label: Label = enemy.get_node_or_null("HealthLabel") as Label
	_expect(label != null, "enemy contains a health indicator")
	if label != null:
		_expect_equal(label.text, "4 / 4", "enemy indicator starts at full health")
	enemy.take_damage(3)
	if label != null:
		_expect_equal(label.text, "1 / 4", "enemy indicator updates after taking damage")
	enemy.free()


func _test_player_damage_indicator_shows_received_damage() -> void:
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	await process_frame

	var label: Label = player.get_node_or_null("DamageIndicator") as Label
	_expect(label != null, "player contains a received-damage indicator")
	player.take_damage(2)
	if label != null:
		_expect_equal(label.text, "-2", "indicator shows the damage actually received")
		_expect(label.visible, "damage indicator becomes visible after a hit")
	player.free()


func _finish() -> void:
	if _failures == 0:
		print("PROGRESSION_INDICATORS_TESTS_PASSED")
		quit(0)
		return

	push_error("PROGRESSION_INDICATORS_TESTS_FAILED: %d" % _failures)
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
