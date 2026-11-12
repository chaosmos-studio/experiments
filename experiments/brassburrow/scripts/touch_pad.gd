extends Control

signal axis_changed(axis: Vector2)

var finger := -1
var axis := Vector2.ZERO
var center := Vector2(92, 92)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var point: Vector2 = (event as InputEventScreenTouch).position - global_position
		if event.pressed and finger == -1 and Rect2(Vector2.ZERO, size).has_point(point):
			finger = event.index
			_move(point)
		elif not event.pressed and event.index == finger:
			finger = -1
			axis = Vector2.ZERO
			axis_changed.emit(axis)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == finger:
		_move((event as InputEventScreenDrag).position - global_position)


func _move(point: Vector2) -> void:
	axis = ((point - center) / 64.0).limit_length()
	axis_changed.emit(axis)
	queue_redraw()


func _draw() -> void:
	draw_circle(center, 71.0, Color(0.13, 0.16, 0.12, 0.38))
	draw_arc(center, 70.0, 0.0, TAU, 48, Color(1.0, 0.91, 0.66, 0.70), 3.0)
	draw_circle(center + axis * 54.0, 29.0, Color("e9c58b"))
	draw_circle(center + axis * 54.0 - Vector2(5, 6), 8.0, Color(1.0, 1.0, 1.0, 0.16))
