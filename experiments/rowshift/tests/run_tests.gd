extends SceneTree

const Board = preload("res://scripts/board.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var board: RefCounted = Board.new()
	for level: int in Board.SCRAMBLES.size():
		board.reset(level)
		_check(not board.won(), "board %d starts scrambled" % level)
		var scramble: Array = Board.SCRAMBLES[level]
		for offset: int in scramble.size():
			var instruction: Array = scramble[scramble.size() - offset - 1]
			_check(board.turn(String(instruction[0]), int(instruction[1]), -int(instruction[2])), "reverse shift works")
		_check(board.won(), "board %d can be solved" % level)
	board.reset(0)
	var opening: Array[int] = board.cells.duplicate()
	_check(board.turn("row", 0, 1), "row shift accepted")
	_check(board.undo(), "undo accepted")
	_check(board.cells == opening and board.moves == 0, "undo restores exact board")
	_check(not board.turn("diagonal", 0, 1), "invalid line rejected")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.size = Vector2(720.0, 960.0)
	for level: int in Board.SCRAMBLES.size():
		var instructions: Array = Board.SCRAMBLES[level]
		for offset: int in instructions.size():
			var instruction: Array = instructions[instructions.size() - offset - 1]
			var axis: String = String(instruction[0])
			var index: int = int(instruction[1])
			var direction: int = -int(instruction[2])
			_click(game, _arrow_point(axis, index, direction))
		_check(game.board.won(), "on-screen arrows solve board %d" % level)
		if level + 1 < Board.SCRAMBLES.size():
			_click(game, Vector2(360.0, 796.0))
			_check(game.board.level == level + 1, "next button opens board %d" % (level + 1))
	game.queue_free()
	print("failures=", failures)
	quit(failures)


func _arrow_point(axis: String, index: int, direction: int) -> Vector2:
	if axis == "row":
		return Vector2(605.0 if direction > 0 else 115.0, 310.0 + float(index) * 90.0)
	return Vector2(225.0 + float(index) * 90.0, 675.0 if direction > 0 else 205.0)


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
