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
	await _test_movement_feel()
	await _test_gesture_controls()
	await _test_palewheel_playthrough()
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


func _test_movement_feel() -> void:
	var pilot: PalewheelCourier = PalewheelCourier.new()
	pilot.control_enabled = false
	root.add_child(pilot)
	await process_frame
	var momentum: Vector2 = Vector2(120, -220)
	pilot.velocity = momentum
	pilot.set_gravity_direction(Vector2.LEFT)
	_check("gravity turns preserve incoming momentum", pilot.velocity.is_equal_approx(momentum))
	_check("the pilot art begins its turn from the previous world angle", absf(pilot.sprite.global_rotation) < 0.02)
	_check("touch jump supports a release", pilot.has_method("release_touch_jump"))
	if pilot.has_method("release_touch_jump"):
		pilot.set_gravity_direction(Vector2.DOWN)
		pilot.velocity = Vector2(0, -500)
		pilot.control_enabled = true
		pilot.release_touch_jump()
		await physics_frame
		await physics_frame
		_check("releasing jump reduces upward speed", pilot.velocity.y > -400.0)
	pilot.queue_free()
	await process_frame


func _test_gesture_controls() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game._on_begin()
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(500, 500)
	press.pressed = true
	game._unhandled_input(press)
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.index = 0
	release.position = Vector2(500, 500)
	release.pressed = false
	game._unhandled_input(release)
	_check("a playfield tap turns gravity once", game.gravity_direction == Vector2.LEFT)
	game.last_shift = -1.0
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._unhandled_input(click)
	_check("a synthetic mouse click after touch does not turn gravity", game.gravity_direction == Vector2.LEFT)
	_check("gravity shift has a keyboard action", InputMap.has_action("shift_gravity"))
	if InputMap.has_action("shift_gravity"):
		game.last_shift = -1.0
		var shift_key: InputEventKey = InputEventKey.new()
		shift_key.physical_keycode = KEY_SHIFT
		shift_key.pressed = true
		game._unhandled_input(shift_key)
		_check("Shift turns gravity", game.gravity_direction == Vector2.UP)
		game.last_shift = -1.0
		game.last_touch_msec = -100000
		game.last_start_msec = -100000
		game._unhandled_input(click)
		_check("a mouse click turns gravity", game.gravity_direction == Vector2.RIGHT)
	game._unhandled_input(press)
	var slide: InputEventScreenDrag = InputEventScreenDrag.new()
	slide.index = 0
	slide.position = Vector2(660, 500)
	game._unhandled_input(slide)
	_check("a horizontal slide walks right", game.pilot.touch_axis == 1.0)
	release.position = slide.position
	game._unhandled_input(release)
	_check("lifting the finger stops walking", game.pilot.touch_axis == 0.0)
	game._unhandled_input(press)
	var upward: InputEventScreenDrag = InputEventScreenDrag.new()
	upward.index = 0
	upward.position = Vector2(500, 370)
	game._unhandled_input(upward)
	_check("an upward swipe queues a jump", game.pilot.touch_jump)
	release.position = upward.position
	game._unhandled_input(release)
	_check("the pilot supports a crouch action", game.pilot.has_method("set_touch_crouch"))
	if game.pilot.has_method("set_touch_crouch"):
		game._unhandled_input(press)
		var downward: InputEventScreenDrag = InputEventScreenDrag.new()
		downward.index = 0
		downward.position = Vector2(500, 640)
		game._unhandled_input(downward)
		release.position = downward.position
		game._unhandled_input(release)
		_check("a downward swipe leaves the pilot crouching", game.pilot.get("touch_crouch") == true)
		game.pilot.call("_set_crouch", true)
		var shape: CollisionShape2D = game.pilot.get_child(0) as CollisionShape2D
		_check("crouching lowers the collision shape", (shape.shape as CapsuleShape2D).height < 78.0)
		game.pilot.call("_set_crouch", false)
		_check("standing restores the collision shape", (shape.shape as CapsuleShape2D).height == 78.0)
	game.queue_free()
	await process_frame


func _test_palewheel_playthrough() -> void:
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
	for level_number: int in range(PalewheelLevels.count()):
		if level_number > 0:
			game._on_begin()
		if level_number == 1:
			var sentry_start: Vector2 = game.sentries[0].position
			for frame: int in range(12):
				await physics_frame
			_check("the clock eye patrols its track", game.sentries[0].position.distance_to(sentry_start) > 10.0)
			game.pilot.position = game.level["checkpoint"]
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			_check("the beacon activates when the pilot reaches it", game.checkpoint_active)
			game.last_shift = -1.0
			game._shift(1)
			await process_frame
			_check("shifting pauses the clock eye", game.sentries[0].freeze_remaining > 0.0 and not game.sentries[0].monitoring)
			game.pilot.position = game.level["shards"][0]
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			await physics_frame
			await physics_frame
			_check("a spark is collected before a hazard hit", game.collected[0])
			game.pilot.position = game.level["hazards"][0].get_center() + Vector2(0, -25)
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			await process_frame
			_check("a hazard sends the pilot to the beacon and keeps sparks", game.pilot.position.distance_to(game.respawn_position) < 30.0 and game.collected[0])
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
		if level_number + 1 < PalewheelLevels.count():
			_check("the next room opens after room %d" % level_number, game.level_index == level_number + 1)
	_check("the dawn ending follows the last room", game.finished)
	game.queue_free()
	await process_frame
