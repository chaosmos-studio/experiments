extends SceneTree

# Hand-typed values in project.godot are read without complaint and can mean something else entirely.
# `window/handheld/orientation="portrait"` is read as an int enum, the string converts to 0, and 0 is
# Landscape. Saving through ProjectSettings writes the type the engine expects.
#
# Run: godot --headless --path . -s res://tools/configure_project.gd -- portrait|landscape [name=My Game]

const PORTRAIT: Dictionary = {
	"viewport": Vector2i(720, 1280),
	"window": Vector2i(405, 720),
	"orientation": DisplayServer.SCREEN_PORTRAIT,
}

# Sensor landscape so the phone can be held either way round.
const LANDSCAPE: Dictionary = {
	"viewport": Vector2i(1920, 1080),
	"window": Vector2i(1280, 720),
	"orientation": DisplayServer.SCREEN_SENSOR_LANDSCAPE,
}

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var layout: Dictionary = LANDSCAPE if args.has("landscape") else PORTRAIT
	for arg: String in args:
		if arg.begins_with("name="):
			ProjectSettings.set_setting("application/config/name", arg.substr(5))

	var viewport: Vector2i = layout["viewport"]
	var window: Vector2i = layout["window"]
	ProjectSettings.set_setting("display/window/size/viewport_width", viewport.x)
	ProjectSettings.set_setting("display/window/size/viewport_height", viewport.y)
	ProjectSettings.set_setting("display/window/size/window_width_override", window.x)
	ProjectSettings.set_setting("display/window/size/window_height_override", window.y)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")
	ProjectSettings.set_setting("display/window/handheld/orientation", int(layout["orientation"]))

	ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
	ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")
	# ETC2/ASTC so textures are VRAM compressed on phones rather than shipped as raw RGBA.
	ProjectSettings.set_setting("rendering/textures/vram_compression/import_etc2_astc", true)
	# The mouse drives touch handlers on desktop. It also makes is_touchscreen_available() true there.
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)

	var status: int = ProjectSettings.save()
	var orientation: Variant = ProjectSettings.get_setting("display/window/handheld/orientation")
	print("configured %s %dx%d, orientation=%s (%s), save status %d" % [
		"landscape" if layout == LANDSCAPE else "portrait", viewport.x, viewport.y,
		orientation, type_string(typeof(orientation)), status])
	quit(0 if status == OK and typeof(orientation) == TYPE_INT else 1)
