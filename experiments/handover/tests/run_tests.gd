extends SceneTree

# Run: godot --headless --path . -s res://tests/run_tests.gd
# CI greps for "0 failed", so keep that wording.

const InputMapGen: GDScript = preload("res://tools/make_input_map.gd")
const GAME: PackedScene = preload("res://scenes/game/game.tscn")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	_test_input_map_is_wired()
	_test_orientation_is_an_int()
	_test_handover_playthrough()
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

func _test_handover_playthrough() -> void:
	var game: Control = GAME.instantiate()
	get_root().add_child(game)
	var model: HandoverModel = game.get("model") as HandoverModel
	game.call("_handle_tap", Vector2(1220.0, 548.0))
	_check("wrong caretaker cannot open the valve", model.assignments[1] == -1)
	game.call("_handle_tap", Vector2(960.0, 930.0))
	game.call("_handle_tap", Vector2(1220.0, 548.0))
	_check("valve waits for the pump", model.assignments[1] == -1)
	game.call("_handle_tap", Vector2(450.0, 930.0))
	game.call("_handle_tap", Vector2(700.0, 548.0))
	game.call("_handle_tap", Vector2(960.0, 930.0))
	game.call("_handle_tap", Vector2(1220.0, 548.0))
	_check("water needs two caretakers", model.cleared)
	game.call("_handle_tap", Vector2(960.0, 660.0))
	_check("light chapter opens", model.stage == 1)
	game.call("_handle_tap", Vector2(560.0, 548.0))
	game.call("_handle_tap", Vector2(1470.0, 930.0))
	game.call("_handle_tap", Vector2(960.0, 548.0))
	game.call("_handle_tap", Vector2(450.0, 930.0))
	game.call("_handle_tap", Vector2(1360.0, 548.0))
	_check("light needs three caretakers", model.cleared)
	game.call("_handle_tap", Vector2(960.0, 660.0))
	game.call("_handle_tap", Vector2(1470.0, 930.0))
	game.call("_handle_tap", Vector2(560.0, 548.0))
	game.call("_handle_tap", Vector2(450.0, 930.0))
	game.call("_handle_tap", Vector2(960.0, 548.0))
	game.call("_handle_tap", Vector2(960.0, 930.0))
	game.call("_handle_tap", Vector2(1360.0, 548.0))
	_check("sunrise needs three caretakers", model.cleared)
	var continue_tap: InputEventMouseButton = InputEventMouseButton.new()
	continue_tap.button_index = MOUSE_BUTTON_LEFT
	continue_tap.pressed = true
	continue_tap.position = Vector2(960.0, 660.0)
	game.call("_gui_input", continue_tap)
	game.call("_gui_input", continue_tap)
	_check("sunrise ending survives a repeated browser tap", model.finished)
	game.call("_handle_tap", Vector2(960.0, 660.0))
	_check("play again resets the story", model.stage == 0 and not model.finished)
	game.queue_free()
