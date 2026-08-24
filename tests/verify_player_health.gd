extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run_test.call_deferred()


func _run_test() -> void:
	var player: Player = Player.new()
	var health_events: Array[Array] = []
	var death_count: Array[int] = [0]

	_expect(player.has_signal(&"health_changed"), "player exposes health_changed")
	_expect(player.has_signal(&"died"), "player exposes died")
	_expect(player.has_method(&"take_damage"), "player exposes take_damage")
	_expect_equal(player.get("max_health"), 10, "player starts with ten maximum health")
	_expect_equal(player.get("current_health"), 10, "player starts at full health")

	if not player.has_signal(&"health_changed") or not player.has_signal(&"died") or not player.has_method(&"take_damage"):
		player.free()
		_finish()
		return

	player.connect(&"health_changed", func(current: int, maximum: int) -> void: health_events.append([current, maximum]))
	player.connect(&"died", func() -> void: death_count[0] += 1)

	player.call(&"take_damage", 0)
	player.call(&"take_damage", -2)
	_expect_equal(player.get("current_health"), 10, "non-positive damage is ignored")
	_expect_equal(health_events, [], "ignored damage emits no health event")

	player.call(&"take_damage", 3)
	_expect_equal(player.get("current_health"), 7, "damage reduces current health")
	_expect_equal(health_events, [[7, 10]], "health change emits current and maximum values")

	player.velocity = Vector2.RIGHT * 100.0
	player.call(&"take_damage", 20)
	_expect_equal(player.get("current_health"), 0, "lethal damage clamps health to zero")
	_expect_equal(death_count[0], 1, "lethal damage emits death once")
	_expect_equal(player.velocity, Vector2.ZERO, "death stops player velocity")

	player.call(&"take_damage", 1)
	_expect_equal(player.get("current_health"), 0, "damage after death is ignored")
	_expect_equal(health_events, [[7, 10], [0, 10]], "damage after death emits no health event")
	_expect_equal(death_count[0], 1, "damage after death does not emit death again")
	player.free()
	_finish()


func _finish() -> void:
	if _failures == 0:
		print("PLAYER_HEALTH_TESTS_PASSED")
		quit(0)
		return

	push_error("PLAYER_HEALTH_TESTS_FAILED: %d" % _failures)
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
