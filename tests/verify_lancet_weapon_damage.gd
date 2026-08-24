extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	_test_increase_damage_updates_state_and_emits_signal()
	_test_new_projectile_receives_current_weapon_damage()

	if _failures == 0:
		print("LANCET_WEAPON_DAMAGE_TESTS_PASSED")
		quit(0)
		return

	push_error("LANCET_WEAPON_DAMAGE_TESTS_FAILED: %d" % _failures)
	quit(1)


func _test_increase_damage_updates_state_and_emits_signal() -> void:
	var weapon: LancetWeapon = LancetWeapon.new()
	var emitted_values: Array[int] = []

	_expect(weapon.has_signal(&"damage_changed"), "weapon exposes damage_changed")
	if weapon.has_signal(&"damage_changed"):
		weapon.connect(&"damage_changed", func(value: int) -> void: emitted_values.append(value))

	if weapon.has_method(&"increase_damage"):
		weapon.call(&"increase_damage")
	else:
		_expect(false, "weapon exposes increase_damage")

	_expect_equal(weapon.get("damage"), 2, "one upgrade raises damage from 1 to 2")
	_expect_equal(emitted_values, [2], "damage_changed emits the updated value")
	weapon.free()


func _test_new_projectile_receives_current_weapon_damage() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	current_scene = world

	var weapon: LancetWeapon = LancetWeapon.new()
	weapon.set("lancet_scene", preload("res://scenes/lancet.tscn"))
	world.add_child(weapon)

	var enemy: CharacterBody2D = CharacterBody2D.new()
	enemy.position = Vector2(100, 0)
	enemy.add_to_group(&"enemies")
	world.add_child(enemy)

	if weapon.has_method(&"increase_damage"):
		weapon.call(&"increase_damage", 2)
	weapon.call(&"_on_attack_timer_timeout")

	var projectile: Lancet
	for child: Node in world.get_children():
		if child is Lancet:
			projectile = child as Lancet
			break

	_expect(projectile != null, "weapon creates a projectile when an enemy is in range")
	if projectile != null:
		_expect_equal(projectile.damage, 3, "new projectile receives current weapon damage")

	current_scene = null
	world.free()


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
