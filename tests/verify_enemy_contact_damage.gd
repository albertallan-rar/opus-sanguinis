extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_contact_damage_repeats_until_player_exits()
	await _test_two_enemies_damage_independently()
	_finish()


func _test_contact_damage_repeats_until_player_exits() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	current_scene = world

	var player: Player = preload("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	world.add_child(enemy)
	await process_frame

	var damage_area: Area2D = enemy.get_node_or_null("DamageArea") as Area2D
	var damage_timer: Timer = enemy.get_node_or_null("DamageTimer") as Timer
	_expect(damage_area != null, "enemy contains a contact damage area")
	_expect(damage_timer != null, "enemy contains an independent damage timer")
	_expect(enemy.has_method(&"_on_damage_area_body_entered"), "enemy handles player entering damage area")
	_expect(enemy.has_method(&"_on_damage_area_body_exited"), "enemy handles player exiting damage area")
	_expect(enemy.has_method(&"_on_damage_timer_timeout"), "enemy handles repeated contact damage")
	if damage_area == null or damage_timer == null or not enemy.has_method(&"_on_damage_area_body_entered"):
		current_scene = null
		world.free()
		return

	enemy.call(&"_on_damage_area_body_entered", player)
	_expect_equal(player.current_health, 9, "contact causes immediate damage")
	_expect(not damage_timer.is_stopped(), "contact starts the damage timer")

	enemy.call(&"_on_damage_area_body_entered", player)
	_expect_equal(player.current_health, 9, "duplicate entry does not cause extra damage")

	enemy.call(&"_on_damage_timer_timeout")
	_expect_equal(player.current_health, 8, "timer repeats damage while contact remains")

	enemy.call(&"_on_damage_area_body_exited", player)
	_expect(damage_timer.is_stopped(), "leaving contact stops the damage timer")
	enemy.call(&"_on_damage_timer_timeout")
	_expect_equal(player.current_health, 8, "timeout after exit causes no damage")

	current_scene = null
	world.free()


func _test_two_enemies_damage_independently() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	current_scene = world

	var player: Player = preload("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	var first_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	var second_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	world.add_child(first_enemy)
	world.add_child(second_enemy)
	await process_frame

	if not first_enemy.has_method(&"_on_damage_area_body_entered"):
		current_scene = null
		world.free()
		return

	first_enemy.call(&"_on_damage_area_body_entered", player)
	second_enemy.call(&"_on_damage_area_body_entered", player)
	_expect_equal(player.current_health, 8, "two enemies apply immediate damage independently")

	current_scene = null
	world.free()


func _finish() -> void:
	if _failures == 0:
		print("ENEMY_CONTACT_DAMAGE_TESTS_PASSED")
		quit(0)
		return

	push_error("ENEMY_CONTACT_DAMAGE_TESTS_FAILED: %d" % _failures)
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
