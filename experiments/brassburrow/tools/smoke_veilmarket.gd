extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node2D = load("res://scenes/veilmarket.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.player.position = game.crowds[0].node.position
	game.try_blend()
	if game.disguise_time <= 0:
		_fail("Borrowing a crowd disguise failed")
		return
	game.player.position = game.guards[0].node.position - Vector2(45, 0)
	game.player.facing = Vector2.RIGHT
	game.player.try_attack()
	if game.guards[0].stun <= 0:
		_fail("The stun did not stop a warden")
		return
	for parcel in game.parcels:
		game.player.position = parcel.node.position
		await process_frame
	if game.delivered != 3:
		_fail("Collecting the three parcels failed")
		return
	game.player.position = Vector2(2240, 750)
	await process_frame
	if game.playing:
		_fail("Reaching the gate with parcels did not win")
		return
	game.start_run()
	game._caught()
	if game.lives != 2:
		_fail("Being caught did not cost a heart")
		return
	print("PASS: disguise, stun, collect, exit, catch and restart")
	game.free()
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
