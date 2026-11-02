extends SceneTree

# Run: godot --headless --path . -s res://tests/run_tests.gd
# CI greps for "0 failed", so keep that wording.

const InputMapGen: GDScript = preload("res://tools/make_input_map.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_input_map_is_wired()
	_test_orientation_is_an_int()
	await _test_compassfall_playthrough()
	print("\n==== TESTS: %d passed, %d failed ====" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _check(name: String, cond: bool) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		print("  FAIL: ", name)

# An action can exist with zero events, and then every is_action_pressed() silently returns false.
func _test_input_map_is_wired() -> void:
	var table: Dictionary = InputMapGen.bindings()
	for action: String in table:
		_check("action %s exists, re-run tools/make_input_map.gd" % action, InputMap.has_action(action))
		if InputMap.has_action(action):
			_check("action %s has bindings" % action, InputMap.action_get_events(action).size() > 0)

# A string here converts to 0, which is Landscape, whatever the string said.
func _test_orientation_is_an_int() -> void:
	var value: Variant = ProjectSettings.get_setting("display/window/handheld/orientation")
	_check("handheld orientation is stored as an int, re-run tools/configure_project.gd",
		typeof(value) == TYPE_INT)


func _test_compassfall_playthrough() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	_check("title opens with play disabled", not game.playing)
	game._on_begin()
	_check("start enables the pilot", game.playing and game.pilot.control_enabled)
	var start_x: float = game.pilot.position.x
	Input.action_press("move_right")
	for frame: int in range(22):
		await physics_frame
	Input.action_release("move_right")
	_check("the pilot runs across the floor", game.pilot.position.x > start_x + 45.0)
	game._shift(1)
	_check("a shift turns gravity and changes the light phase", game.gravity_direction == Vector2.LEFT and game.phase == 1)
	game._restart()
	for level_number: int in range(CompassLevels.count()):
		if level_number > 0:
			game._on_begin()
		for spark: Vector2 in game.level["shards"]:
			game.pilot.position = spark
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
		_check("all sparks collect in room %d" % level_number, not game.collected.has(false))
		if game.level["pad"] != Vector2.ZERO:
			game._on_pad_body(game.cargo)
			_check("cargo plate arms in room %d" % level_number, game.pad_armed)
		_check("exit unlocks in room %d" % level_number, game.world.door_open)
		game.pilot.position = game.level["exit"]
		game.pilot.velocity = Vector2.ZERO
		game.pilot.reset_physics_interpolation()
		await physics_frame
		await physics_frame
		if level_number + 1 < CompassLevels.count():
			_check("the next room opens after room %d" % level_number, game.level_index == level_number + 1)
	_check("the dawn ending follows the last room", game.finished)
	game.queue_free()
	await process_frame
