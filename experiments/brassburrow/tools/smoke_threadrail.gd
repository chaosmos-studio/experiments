extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node2D = load("res://scenes/threadrail.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	var start: Vector2 = game.player.position
	game.try_hook()
	if not is_instance_valid(game.player.hook):
		_fail("The hook did not catch the first post")
		return
	for frame in 50:
		await physics_frame
	if game.player.position.distance_to(start) < 10:
		_fail("The rope did not pull the runner")
		return
	game.try_reel()
	if not game.player.reeling:
		_fail("The reel did not shorten the rope")
		return
	game.try_hook()
	if is_instance_valid(game.player.hook):
		_fail("The hook did not release")
		return
	game.player.try_dash()
	if game.player.velocity.length() < 100:
		_fail("Dash did not add momentum")
		return
	game.player.velocity = Vector2.ZERO
	for index in range(1, 6):
		game.player.position = game.ISLANDS[index]
		game.player.velocity = Vector2.ZERO
		await process_frame
		await process_frame
	if game.checkpoint != 5 or game.playing:
		_fail("The five landings did not finish the run")
		return
	game.start_run()
	game._fall()
	if game.hearts != 2 or game.checkpoint != 0:
		_fail("The current did not return the runner to the checkpoint")
		return
	print("PASS: hook pull, reel, release, dash, landings, finish and current")
	game.free()
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
