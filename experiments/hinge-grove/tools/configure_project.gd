extends SceneTree

func _initialize() -> void:
	var settings: Dictionary = {
		"application/config/name": "Hinge Grove",
		"application/config/description": "Swing a seed. Grow a little garden.",
		"application/run/main_scene": "res://scenes/main.tscn",
		"application/config/icon": "res://assets/icon.svg",
		"application/boot_splash/show_image": false,
		"application/boot_splash/bg_color": Color("f5f3eb"),
		"display/window/size/viewport_width": 720,
		"display/window/size/viewport_height": 1280,
		"display/window/size/window_width_override": 405,
		"display/window/size/window_height_override": 720,
		"display/window/handheld/orientation": 1,
		"display/window/stretch/mode": "canvas_items",
		"display/window/stretch/aspect": "expand",
		"rendering/renderer/rendering_method": "gl_compatibility",
		"rendering/renderer/rendering_method.mobile": "gl_compatibility",
		"rendering/environment/defaults/default_clear_color": Color("f5f3eb"),
		"rendering/textures/vram_compression/import_etc2_astc": true,
		"input_devices/pointing/emulate_touch_from_mouse": false,
		"input_devices/pointing/emulate_mouse_from_touch": false
	}
	for setting: String in settings:
		ProjectSettings.set_setting(setting, settings[setting])
	var keys: Dictionary = {"undo": KEY_Z, "retry": KEY_R, "hint": KEY_H, "back": KEY_ESCAPE}
	for action: String in keys:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = int(keys[action])
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": [event]})
	ProjectSettings.save()
	quit()
