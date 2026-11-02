extends SceneTree

const Run = preload("res://scripts/run.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run: RefCounted = Run.new()
	_check(run.mode == Run.Mode.READY, "run opens ready")
	_check(not run.shift(), "gravity stays put before start")
	run.start()
	for frame: int in 210:
		run.step(1.0 / 60.0)
		if run.mode == Run.Mode.CRASHED:
			break
	_check(run.mode == Run.Mode.CRASHED, "first bottom barrier ends an untouched run")
	run.start()
	_check(run.score == 0 and run.side == 1, "retry resets score and pull")
	_check(run.shift() and run.side == 0, "tap reverses gravity")
	for frame: int in 130:
		run.step(1.0 / 60.0)
	_check(run.mode == Run.Mode.RUNNING, "top rail clears the first barrier")
	_check(run.score >= 1, "passing a barrier scores")
	_check(run.best >= 1, "best score tracks the run")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.size = Vector2(720.0, 1440.0)
	_click(game)
	_check(game.run.mode == Run.Mode.RUNNING, "a screen tap starts the run")
	_click(game)
	_check(game.run.side == 0, "a second screen tap flips gravity")
	game.queue_free()
	await process_frame
	print("failures=", failures)
	quit(failures)


func _click(game: Control) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(360.0, 720.0)
	game._input(event)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
