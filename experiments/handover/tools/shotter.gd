extends Node

# This machine has no Xvfb, so it opens a window on the real display for a moment.
# Run: DISPLAY=:0 godot --path . res://tools/shotter.tscn -- <scene_path> <frames> <out_name>

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/game/game.tscn"
	var frames: int = int(args[1]) if args.size() > 1 else 120
	var out_name: String = args[2] if args.size() > 2 else "shot"
	var scene: Node = load(scene_path).instantiate()
	add_child(scene)
	for i: int in range(frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "user://%s.png" % out_name
	img.save_png(path)
	print("SHOT_SAVED ", ProjectSettings.globalize_path(path))
	get_tree().quit()
