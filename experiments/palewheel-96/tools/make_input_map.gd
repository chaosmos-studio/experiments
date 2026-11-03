extends SceneTree

# An [input] section Godot cannot parse into InputEvent objects is not an error, it is an action with no
# bindings, and every is_action_pressed() returns false without a warning. Define the bindings here and let
# the engine serialise them. tests/run_tests.gd asserts every action has events.
#
# Run after changing a binding: godot --headless --path . -s res://tools/make_input_map.gd

const DEADZONE: float = 0.2

# Physical keycodes, so WASD stays under the same fingers on non-QWERTY layouts.
static func bindings() -> Dictionary:
	return {
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)],
		"jump": [_key(KEY_W), _key(KEY_UP), _key(KEY_SPACE), _button(JOY_BUTTON_A)],
		"crouch": [_key(KEY_S), _key(KEY_DOWN), _button(JOY_BUTTON_B)],
		"shift_gravity": [_key(KEY_SHIFT), _button(JOY_BUTTON_X)],
		"pause": [_key(KEY_ESCAPE), _key(KEY_P), _button(JOY_BUTTON_START)],
		"retry": [_key(KEY_R)],
		"debug_toggle": [_key(KEY_F3)],
	}

func _initialize() -> void:
	var table: Dictionary = bindings()
	# Drop actions no longer in the table, so a renamed action does not linger in project.godot.
	for property: Dictionary in ProjectSettings.get_property_list():
		var setting: String = property["name"]
		if setting.begins_with("input/") and not setting.begins_with("input/ui_") and not table.has(setting.substr(6)):
			ProjectSettings.set_setting(setting, null)
	for action: String in table:
		var events: Array[InputEvent] = []
		for event: InputEvent in table[action]:
			events.append(event)
		ProjectSettings.set_setting("input/" + action, {"deadzone": DEADZONE, "events": events})
	var status: int = ProjectSettings.save()
	for action: String in table:
		var setting: Dictionary = ProjectSettings.get_setting("input/" + action)
		print("  %-14s %d events" % [action, (setting["events"] as Array).size()])
	print("input map written for %d actions (status %d)" % [table.size(), status])
	quit(0 if status == OK else 1)

static func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	return event

static func _button(button: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	return event

# The sign of axis_value picks which half of the stick fires the action.
static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
