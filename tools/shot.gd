extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "/tmp/gameoff-shot.png"
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Could not save screenshot: %s" % path)
		quit(1)
		return
	print("SHOT_SAVED ", path)
	quit()
