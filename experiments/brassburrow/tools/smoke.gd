extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	var initial_position: Vector2 = game.player.position
	Input.action_press("move_right")
	for frame in 15:
		await physics_frame
	Input.action_release("move_right")
	if game.player.position.x <= initial_position.x + 25.0:
		_fail("The player did not walk across the room")
		return
	var pod: Dictionary = game.pods[0]
	game.player.position = pod.node.position - Vector2(35, 0)
	game.player.velocity = Vector2.ZERO
	game.player.facing = Vector2.RIGHT
	game.player.try_attack()
	await create_timer(0.32).timeout
	game.player.try_attack()
	if game.copper != 8:
		_fail("Harvesting did not add copper")
		return
	game.player.position = game.hearth.position + Vector2(80, 0)
	game.player.facing = Vector2.RIGHT
	game.try_build()
	if game.turrets.size() != 1 or game.copper != 3:
		_fail("The cannon did not build with copper")
		return
	game.damage_hearth(40)
	game.try_repair()
	if game.hearth_health != 190 or game.copper != 0:
		_fail("The hearth did not consume copper to repair")
		return
	game._spawn_enemy()
	if game.enemies.is_empty():
		_fail("The beetle wave did not spawn")
		return
	game.damage_hearth(200)
	if game.playing:
		_fail("The run did not end when the hearth fell")
		return
	game.start_run()
	if not game.playing or game.hearth_health != 200 or not game.turrets.is_empty():
		_fail("Restart did not reset the world")
		return
	print("PASS: movement, harvest, build, repair, wave, loss and restart")
	game.free()
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
