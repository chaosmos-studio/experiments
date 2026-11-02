extends Control

const Board = preload("res://scripts/board.gd")
const INK: Color = Color("172136")
const LIGHT: Color = Color("f4f0e7")
const DAWN: Color = Color("f1b67b")
const DUSK: Color = Color("78ccbe")
const CELL: float = 72.0
const BOARD_ORIGIN: Vector2 = Vector2(108.0, 230.0)

var board: RefCounted = Board.new()
var notice: String = ""
var notice_time: float = 0.0


func _ready() -> void:
	board.reset(0)
	print("PHASEWALK_READY")
	queue_redraw()


func _process(delta: float) -> void:
	if notice_time > 0.0:
		notice_time = maxf(0.0, notice_time - delta)
		if notice_time == 0.0:
			queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retry"):
		board.reset(board.level)
		_refresh()
	elif board.won() and event.is_action_pressed("ui_accept"):
		_advance()
	elif event.is_action_pressed("phase_shift"):
		_try_shift()
	elif event.is_action_pressed("ui_left"):
		_try_move(Vector2i.LEFT)
	elif event.is_action_pressed("ui_right"):
		_try_move(Vector2i.RIGHT)
	elif event.is_action_pressed("ui_up"):
		_try_move(Vector2i.UP)
	elif event.is_action_pressed("ui_down"):
		_try_move(Vector2i.DOWN)


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
	if Rect2(555.0, 52.0, 108.0, 64.0).has_point(point):
		board.reset(board.level)
		_refresh()
	elif board.won() and Rect2(180.0, 790.0, 360.0, 84.0).has_point(point):
		_advance()
	elif Rect2(68.0, 786.0, 104.0, 88.0).has_point(point):
		_try_move(Vector2i.LEFT)
	elif Rect2(188.0, 786.0, 104.0, 88.0).has_point(point):
		_try_move(Vector2i.UP)
	elif Rect2(308.0, 786.0, 104.0, 88.0).has_point(point):
		_try_move(Vector2i.DOWN)
	elif Rect2(428.0, 786.0, 104.0, 88.0).has_point(point):
		_try_move(Vector2i.RIGHT)
	elif Rect2(548.0, 786.0, 104.0, 88.0).has_point(point):
		_try_shift()
	else:
		var cell: Vector2i = Vector2i(floori((point.x - BOARD_ORIGIN.x) / CELL), floori((point.y - BOARD_ORIGIN.y) / CELL))
		var direction: Vector2i = cell - board.position
		if absi(direction.x) + absi(direction.y) == 1:
			_try_move(direction)
	get_viewport().set_input_as_handled()


func _try_move(direction: Vector2i) -> void:
	if board.move(direction):
		_refresh()
	else:
		_show_notice("That way is blocked.")


func _try_shift() -> void:
	if board.shift():
		_refresh()
	elif board.shifts >= Board.SHIFT_BUDGETS[board.level]:
		_show_notice("No shifts left. Retry this board.")
	else:
		_show_notice("You cannot shift inside a wall.")


func _advance() -> void:
	if board.level + 1 < Board.SHIFT_BUDGETS.size():
		board.reset(board.level + 1)
		_refresh()
	else:
		_show_notice("All corridors crossed. Try another draft.")


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
	var is_dawn: bool = board.phase == 0
	var background: Color = INK if is_dawn else LIGHT
	var foreground: Color = LIGHT if is_dawn else INK
	var accent: Color = DAWN if is_dawn else DUSK
	draw_rect(Rect2(0.0, 0.0, 720.0, 960.0), background)
	_text("PHASEWALK", Vector2(70.0, 96.0), 45, foreground)
	_text("BOARD %d     %s REALITY" % [board.level + 1, "DAWN" if is_dawn else "DUSK"], Vector2(70.0, 153.0), 22, accent)
	_text("Shifts: %d / %d" % [board.shifts, Board.SHIFT_BUDGETS[board.level]], Vector2(70.0, 192.0), 23, foreground)
	_button(Rect2(555.0, 52.0, 108.0, 64.0), "RETRY", foreground, background)
	var current: PackedStringArray = board.walls(board.phase)
	var other: PackedStringArray = board.walls(1 - board.phase)
	for y: int in Board.HEIGHT:
		for x: int in Board.WIDTH:
			var rect: Rect2 = Rect2(BOARD_ORIGIN + Vector2(x, y) * CELL, Vector2.ONE * (CELL - 4.0))
			var wall: bool = current[y][x] == "#"
			var cell_color: Color = accent if wall else foreground.darkened(0.72) if is_dawn else Color("d8d8d0")
			draw_rect(rect, cell_color)
			if not wall and other[y][x] == "#":
				draw_rect(rect.grow(-12.0), accent.darkened(0.35), false, 3.0)
	var exit_center: Vector2 = BOARD_ORIGIN + (Vector2(Board.EXIT) + Vector2(0.5, 0.5)) * CELL
	draw_circle(exit_center, 20.0, Color("e6d76d"))
	draw_circle(exit_center, 11.0, background)
	var player_center: Vector2 = BOARD_ORIGIN + (Vector2(board.position) + Vector2(0.5, 0.5)) * CELL
	draw_circle(player_center, 25.0, foreground)
	draw_circle(player_center, 10.0, accent)
	_text("Open cells change when you shift.", Vector2(70.0, 757.0), 20, foreground)
	if board.won():
		_button(Rect2(180.0, 790.0, 360.0, 84.0), "NEXT BOARD" if board.level < 2 else "FINISHED", accent, background)
	else:
		_button(Rect2(68.0, 786.0, 104.0, 88.0), "LEFT", foreground, background)
		_button(Rect2(188.0, 786.0, 104.0, 88.0), "UP", foreground, background)
		_button(Rect2(308.0, 786.0, 104.0, 88.0), "DOWN", foreground, background)
		_button(Rect2(428.0, 786.0, 104.0, 88.0), "RIGHT", foreground, background)
		_button(Rect2(548.0, 786.0, 104.0, 88.0), "SHIFT", accent, background)
	_text(notice if notice_time > 0.0 else "Arrows move. Space shifts. Reach the gold ring.", Vector2(70.0, 921.0), 19, foreground)
	draw_set_transform(Vector2.ZERO)


func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _button(rect: Rect2, label: String, border: Color, fill: Color) -> void:
	draw_rect(rect, border)
	draw_rect(rect.grow(-3.0), fill)
	var width: float = ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	_text(label, Vector2(rect.position.x + (rect.size.x - width) * 0.5, rect.position.y + rect.size.y * 0.63), 20, border)
