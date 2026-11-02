extends SceneTree

const Board = preload("res://scripts/board.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var shift_key: InputEventKey = InputEventKey.new()
	shift_key.physical_keycode = KEY_SHIFT
	shift_key.pressed = true
	_check(InputMap.event_is_action(shift_key, "phase_shift"), "Shift key changes reality")
	var space_key: InputEventKey = InputEventKey.new()
	space_key.physical_keycode = KEY_SPACE
	space_key.pressed = true
	_check(InputMap.event_is_action(space_key, "phase_shift"), "Space key changes reality")
	var board: RefCounted = Board.new()
	var routes: Array[Array] = [
		["R", "R", "S", "R", "R", "S", "R", "R"],
		["R", "S", "R", "R", "S", "R", "R", "R"],
		["S", "R", "U", "R", "S", "R", "R", "S", "R", "R", "D"],
	]
	for level: int in Board.SHIFT_BUDGETS.size():
		board.reset(level)
		_check(not board.won(), "board %d starts unfinished" % level)
		for step: String in routes[level]:
			_check(_apply_step(board, step), "board %d step %s works" % [level, step])
		_check(board.won(), "board %d can be crossed" % level)
		_check(board.shifts <= Board.SHIFT_BUDGETS[level], "board %d fits shift budget" % level)
	board.reset(0)
	_check(not board.move(Vector2i.LEFT), "cannot leave board")
	_check(board.move(Vector2i.RIGHT), "open cell accepts a move")
	_check(not board.move(Vector2i(2, 0)), "diagonal and long moves are rejected")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.size = Vector2(720.0, 960.0)
	_check(game.board.position == Board.START, "main scene starts at entrance")
	for level: int in routes.size():
		for step: String in routes[level]:
			_click(game, _step_point(step))
		_check(game.board.won(), "on-screen controls cross board %d" % level)
		if level + 1 < routes.size():
			_click(game, Vector2(360.0, 830.0))
			_check(game.board.level == level + 1, "next button opens board %d" % (level + 1))
	game.queue_free()
	print("failures=", failures)
	quit(failures)


func _apply_step(board: RefCounted, step: String) -> bool:
	match step:
		"S": return board.shift()
		"R": return board.move(Vector2i.RIGHT)
		"U": return board.move(Vector2i.UP)
		"D": return board.move(Vector2i.DOWN)
		_: return false


func _step_point(step: String) -> Vector2:
	match step:
		"S": return Vector2(600.0, 830.0)
		"R": return Vector2(480.0, 830.0)
		"U": return Vector2(240.0, 830.0)
		"D": return Vector2(360.0, 830.0)
		_: return Vector2.ZERO


func _click(game: Control, point: Vector2) -> void:
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = point
	game._input(click)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
