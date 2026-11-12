extends Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := "res://scenes/veilmarket.tscn" if args.has("veilmarket") else "res://scenes/threadrail.tscn" if args.has("threadrail") else "res://scenes/main.tscn"
	var game: Node2D = load(scene_path).instantiate()
	add_child(game)
	if args.has("play"):
		game.start_run()
	for i in 90:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "/tmp/%s-%s.png" % [game.name.to_lower(), "play" if args.has("play") else "intro"]
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT_SAVED ", path)
	get_tree().quit()
