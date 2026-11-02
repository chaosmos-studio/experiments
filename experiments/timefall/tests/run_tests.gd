extends SceneTree

const Descent = preload("res://scripts/descent.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var descent: RefCounted = Descent.new()
	_check(descent.mode == Descent.Mode.READY, "descent opens ready")
	_check(not descent.shift(), "time stays normal before start")
	descent.start()
	descent.steer(900.0)
	_check(descent.target_x == 672.0, "steering stays inside the tower")
	descent.steer(360.0)
	for frame: int in 125:
		descent.step(1.0 / 60.0)
	_check(descent.mode == Descent.Mode.RUNNING, "center route clears the first gate")
	_check(descent.score >= 1, "clearing a gate scores")
	for frame: int in 120:
		descent.step(1.0 / 60.0)
		if descent.mode == Descent.Mode.CRASHED:
			break
	_check(descent.mode == Descent.Mode.CRASHED, "next offset gate catches an unsteered pilot")
	descent.start()
	_check(descent.score == 0 and descent.charge == 1.0, "retry refills time charge")
	_check(descent.shift() and descent.slow, "time shift activates")
	descent.step(1.0)
	_check(descent.charge < 1.0 and descent.charge > 0.0, "slow time drains charge")
	_check(descent.shift() and not descent.slow, "time shift returns to normal")
	var spent: float = descent.charge
	descent.step(0.5)
	_check(descent.charge > spent, "normal flight recharges time")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.size = Vector2(720.0, 1440.0)
	_click(game, Vector2(340.0, 680.0))
	_check(game.descent.mode == Descent.Mode.RUNNING, "a screen tap starts the descent")
	_click(game, Vector2(530.0, 1260.0))
	_check(game.descent.slow, "the shift button slows time")
	_click(game, Vector2(580.0, 680.0))
	_check(game.descent.target_x == 580.0, "touch steers toward the chosen gap")
	game.queue_free()
	await process_frame
	print("failures=", failures)
	quit(failures)


func _click(game: Control, point: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	game._input(event)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
