extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_test.call_deferred()


func _run_test() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	current_scene = world

	var player: Player = preload("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	var hud: HUD = preload("res://scenes/hud.tscn").instantiate()
	world.add_child(hud)
	await process_frame

	var damage_label: Label = hud.get_node_or_null("LancetDamageLabel") as Label
	_expect(damage_label != null, "HUD contains a permanent Lancet damage label")
	if damage_label != null:
		_expect_equal(damage_label.text, "Dano da Lanceta: 1", "HUD displays initial weapon damage")

	var weapon: LancetWeapon = player.get_node("LancetWeapon") as LancetWeapon
	weapon.increase_damage()
	if damage_label != null:
		_expect_equal(damage_label.text, "Dano da Lanceta: 2", "HUD updates when weapon damage changes")

	current_scene = null
	world.free()

	if _failures == 0:
		print("HUD_WEAPON_DAMAGE_TESTS_PASSED")
		quit(0)
		return

	push_error("HUD_WEAPON_DAMAGE_TESTS_FAILED: %d" % _failures)
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
