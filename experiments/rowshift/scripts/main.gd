extends Control

const Board = preload("res://scripts/board.gd")
const PAPER: Color = Color("f0ebdc")
const INK: Color = Color("243442")
const MUTED: Color = Color("75838b")
const SLOT: Color = Color("d8d8cf")
const STONES: Array[Color] = [Color.TRANSPARENT, Color("e47d65"), Color("67ab9e"), Color("718ec9"), Color("d1aa56")]
const CELL: float = 90.0
const BOARD_ORIGIN: Vector2 = Vector2(180.0, 265.0)

var board: RefCounted = Board.new()
var notice: String = ""
var notice_time: float = 0.0


func _ready() -> void:
	board.reset(0)
	print("ROWSHIFT_READY")
	queue_redraw()


func _process(delta: float) -> void:
	if notice_time > 0.0:
		notice_time = maxf(0.0, notice_time - delta)
		if notice_time == 0.0:
			queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		if board.undo():
			_refresh()
	elif event.is_action_pressed("retry"):
		board.reset(board.level)
		_refresh()
	elif board.won() and event.is_action_pressed("ui_accept"):
		_advance()


func _input(event: InputEvent) -> void:
	var point: Vector2 = Vector2(-1.0, -1.0)
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
			return
		point = mouse.position
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if not touch.pressed:
			return
		point = touch.position
	else:
		return
	point = _to_design(point)
	if Rect2(70.0, 760.0, 180.0, 72.0).has_point(point):
		if board.undo():
			_refresh()
	elif Rect2(470.0, 760.0, 180.0, 72.0).has_point(point):
		board.reset(board.level)
		_refresh()
	elif board.won() and Rect2(240.0, 760.0, 240.0, 72.0).has_point(point):
		_advance()
	else:
		for row: int in Board.SIZE:
			var y: float = BOARD_ORIGIN.y + float(row) * CELL + 9.0
			if Rect2(72.0, y, 86.0, 72.0).has_point(point):
				_turn("row", row, -1)
				break
			if Rect2(562.0, y, 86.0, 72.0).has_point(point):
				_turn("row", row, 1)
				break
		for column: int in Board.SIZE:
			var x: float = BOARD_ORIGIN.x + float(column) * CELL + 9.0
			if Rect2(x, 165.0, 72.0, 82.0).has_point(point):
				_turn("column", column, -1)
				break
			if Rect2(x, 635.0, 72.0, 82.0).has_point(point):
				_turn("column", column, 1)
				break
	get_viewport().set_input_as_handled()


func _turn(axis: String, index: int, direction: int) -> void:
	if board.turn(axis, index, direction):
		_refresh()
	else:
		_show_notice("Already aligned. Try the next board.")


func _advance() -> void:
	if board.level + 1 < Board.SCRAMBLES.size():
		board.reset(board.level + 1)
		_refresh()
	else:
		_show_notice("All patterns aligned. Try another draft.")


func _refresh() -> void:
	notice = ""
	notice_time = 0.0
	queue_redraw()


func _show_notice(message: String) -> void:
	notice = message
	notice_time = 2.0
	queue_redraw()


func _to_design(point: Vector2) -> Vector2:
	var scale_factor: float = minf(size.x / 720.0, size.y / 960.0)
	var offset: Vector2 = (size - Vector2(720.0, 960.0) * scale_factor) * 0.5
	return (point - offset) / scale_factor


func _draw() -> void:
	var scale_factor: float = minf(size.x / 720.0, size.y / 960.0)
	var offset: Vector2 = (size - Vector2(720.0, 960.0) * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(0.0, 0.0, 720.0, 960.0), PAPER)
	_text("ROWSHIFT", Vector2(70.0, 92.0), 48, INK)
	_text("BOARD %d / 3       MOVES %d" % [board.level + 1, board.moves], Vector2(70.0, 141.0), 21, MUTED)
	for row: int in Board.SIZE:
		var y: float = BOARD_ORIGIN.y + float(row) * CELL
		_button(Rect2(72.0, y + 9.0, 86.0, 72.0), "<")
		_button(Rect2(562.0, y + 9.0, 86.0, 72.0), ">")
	for column: int in Board.SIZE:
		var x: float = BOARD_ORIGIN.x + float(column) * CELL
		_button(Rect2(x + 9.0, 165.0, 72.0, 82.0), "UP")
		_button(Rect2(x + 9.0, 635.0, 72.0, 82.0), "DN")
	for row: int in Board.SIZE:
		for column: int in Board.SIZE:
			var index: int = row * Board.SIZE + column
			var center: Vector2 = BOARD_ORIGIN + Vector2(float(column) + 0.5, float(row) + 0.5) * CELL
			draw_rect(Rect2(center - Vector2.ONE * 42.0, Vector2.ONE * 84.0), SLOT)
			var goal_stone: int = Board.GOAL[index]
			if goal_stone > 0:
				draw_circle(center, 29.0, STONES[goal_stone])
				draw_circle(center, 23.0, SLOT)
			var stone: int = board.cells[index]
			if stone > 0:
				draw_circle(center, 21.0, STONES[stone])
				draw_circle(center - Vector2(6.0, 6.0), 4.0, PAPER)
	_text("Shift a whole line. The stones wrap around.", Vector2(70.0, 743.0), 19, INK)
	_button(Rect2(70.0, 760.0, 180.0, 72.0), "UNDO")
	_button(Rect2(470.0, 760.0, 180.0, 72.0), "RETRY")
	if board.won():
		_button(Rect2(240.0, 760.0, 240.0, 72.0), "NEXT")
	_text(notice if notice_time > 0.0 else "Match every stone to its colored ring.", Vector2(70.0, 887.0), 21, INK)
	draw_set_transform(Vector2.ZERO)


func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _button(rect: Rect2, label: String) -> void:
	draw_rect(rect, INK)
	draw_rect(rect.grow(-3.0), PAPER)
	var width: float = ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	_text(label, Vector2(rect.position.x + (rect.size.x - width) * 0.5, rect.position.y + rect.size.y * 0.62), 20, INK)
