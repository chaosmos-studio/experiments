extends Control

const Descent = preload("res://scripts/descent.gd")
const FONT: Font = preload("res://assets/fonts/Manrope.ttf")
const SHIFT_SOUND: AudioStream = preload("res://assets/audio/shift.wav")
const PASS_SOUND: AudioStream = preload("res://assets/audio/pass.wav")
const CRASH_SOUND: AudioStream = preload("res://assets/audio/crash.wav")
const DEEP: Color = Color("081225")
const WHITE: Color = Color("eef7ff")
const MUTED: Color = Color("9ab2c9")
const CYAN: Color = Color("79e3ed")
const BLUE: Color = Color("446ac8")
const CORAL: Color = Color("ff836d")
const DESIGN: Vector2 = Vector2(720.0, 1440.0)
const SHIFT_BUTTON: Rect2 = Rect2(405.0, 1207.0, 255.0, 114.0)

@onready var sound: AudioStreamPlayer = $Sound

var descent: RefCounted = Descent.new()
var clock: float = 0.0
var trail: Array[Vector2] = []
var trail_timer: float = 0.0
var flash: float = 0.0


func _ready() -> void:
	print("TIMEFALL_READY")
	queue_redraw()


func _exit_tree() -> void:
	if is_instance_valid(sound):
		sound.stop()
		sound.stream = null


func _process(delta: float) -> void:
	clock += delta
	flash = maxf(0.0, flash - delta * 2.4)
	if descent.mode == Descent.Mode.RUNNING:
		var horizontal: float = Input.get_axis("ui_left", "ui_right")
		if horizontal != 0.0:
			descent.steer(descent.target_x + horizontal * 700.0 * delta)
		var previous_score: int = descent.score
		descent.step(delta)
		if descent.score > previous_score:
			_play(PASS_SOUND)
			print("TIMEFALL_SCORE %d" % descent.score)
		if descent.mode == Descent.Mode.CRASHED:
			flash = 1.0
			_play(CRASH_SOUND)
			print("TIMEFALL_CRASH %d" % descent.score)
		trail_timer += delta
		if trail_timer >= 0.035:
			trail_timer = 0.0
			trail.push_front(Vector2(descent.player_x, Descent.PLAYER_Y))
			if trail.size() > 18:
				trail.pop_back()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_press(_to_design(mouse.position))
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_press(_to_design(touch.position))
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if descent.mode == Descent.Mode.RUNNING:
			descent.steer(_to_design(drag.position).x)
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if descent.mode == Descent.Mode.RUNNING and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			descent.steer(_to_design(motion.position).x)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shift_time"):
		_shift()
	elif event.is_action_pressed("retry") and descent.mode == Descent.Mode.CRASHED:
		_start()


func _press(point: Vector2) -> void:
	if descent.mode != Descent.Mode.RUNNING:
		_start()
	elif SHIFT_BUTTON.has_point(point):
		_shift()
	else:
		descent.steer(point.x)
		print("TIMEFALL_STEER %d" % roundi(descent.target_x))
	queue_redraw()


func _start() -> void:
	descent.start()
	trail.clear()
	flash = 0.0
	print("TIMEFALL_START")
	queue_redraw()


func _shift() -> void:
	if descent.shift():
		flash = 0.32
		_play(SHIFT_SOUND)
		print("TIMEFALL_SHIFT %d" % int(descent.slow))
		queue_redraw()


func _play(stream: AudioStream) -> void:
	if DisplayServer.get_name() == "headless":
		return
	sound.stop()
	sound.stream = stream
	sound.play()


func _to_design(point: Vector2) -> Vector2:
	var scale_factor: float = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	var offset: Vector2 = (size - DESIGN * scale_factor) * 0.5
	return (point - offset) / scale_factor


func _draw() -> void:
	var scale_factor: float = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	var offset: Vector2 = (size - DESIGN * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(Vector2.ZERO, DESIGN), DEEP)
	_draw_tower()
	for gate: RefCounted in descent.gates:
		_draw_gate(gate)
	_draw_pilot()
	_draw_hud()
	if descent.mode != Descent.Mode.RUNNING:
		_draw_overlay()
	if descent.slow:
		draw_rect(Rect2(Vector2.ZERO, DESIGN), Color(CYAN, 0.045))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, DESIGN), Color(1.0, 1.0, 1.0, flash * 0.09))
	draw_set_transform(Vector2.ZERO)


func _draw_tower() -> void:
	draw_rect(Rect2(0.0, 210.0, 720.0, 905.0), Color("0d1b37"))
	for column: int in 7:
		var x: float = 54.0 + float(column) * 102.0
		draw_line(Vector2(x, 205.0), Vector2(x, 1130.0), Color(BLUE, 0.20), 2.0)
	for index: int in 34:
		var x: float = float((index * 173 + 29) % 620) + 50.0
		var travel: float = descent.distance * (0.3 if index % 3 else 0.6)
		var y: float = fposmod(float(index) * 127.0 + travel, 1020.0) + 160.0
		var length: float = 15.0 + float(index % 5) * 10.0
		draw_line(Vector2(x, y), Vector2(x, y + length), Color(CYAN, 0.12 + float(index % 4) * 0.04), 2.0)
	draw_line(Vector2(30.0, 210.0), Vector2(30.0, 1130.0), Color(CYAN, 0.65), 4.0)
	draw_line(Vector2(690.0, 210.0), Vector2(690.0, 1130.0), Color(CYAN, 0.65), 4.0)


func _draw_gate(gate: RefCounted) -> void:
	var left_end: float = gate.gap_x - Descent.GAP_HALF_WIDTH
	var right_start: float = gate.gap_x + Descent.GAP_HALF_WIDTH
	var top: float = gate.y - Descent.GATE_THICKNESS * 0.5
	var left: Rect2 = Rect2(30.0, top, left_end - 30.0, Descent.GATE_THICKNESS)
	var right: Rect2 = Rect2(right_start, top, 690.0 - right_start, Descent.GATE_THICKNESS)
	for rect: Rect2 in [left, right]:
		draw_rect(rect.grow(13.0), Color(CORAL, 0.11))
		draw_rect(rect, CORAL)
		draw_rect(rect.grow(-9.0), Color("6b3042"))
	for edge: float in [left_end, right_start]:
		draw_line(Vector2(edge, gate.y - 43.0), Vector2(edge, gate.y + 43.0), Color.WHITE, 5.0)
	var glint: float = 0.35 + 0.25 * sin(clock * 4.0 + gate.y * 0.01)
	draw_circle(Vector2(gate.gap_x, gate.y), 8.0, Color(CYAN, glint))


func _draw_pilot() -> void:
	for index: int in trail.size():
		var point: Vector2 = trail[index] - Vector2(0.0, float(index) * 12.0)
		var alpha: float = 0.28 * (1.0 - float(index) / float(trail.size()))
		draw_circle(point, 18.0 - float(index) * 0.5, Color(CYAN, alpha))
	var point: Vector2 = Vector2(descent.player_x, Descent.PLAYER_Y)
	draw_circle(point, 51.0 if descent.slow else 40.0, Color(CYAN, 0.08))
	draw_circle(point, 28.0, Color(CYAN, 0.22))
	draw_colored_polygon(PackedVector2Array([point + Vector2(0.0, 29.0), point + Vector2(-24.0, -18.0), point + Vector2(0.0, -8.0), point + Vector2(24.0, -18.0)]), WHITE)
	draw_circle(point + Vector2(0.0, 2.0), 6.0, CYAN)


func _draw_hud() -> void:
	_text("TIMEFALL", Vector2(58.0, 98.0), 50, WHITE)
	_text("BEND THE DESCENT", Vector2(60.0, 148.0), 25, CYAN)
	_text("%02d" % descent.score, Vector2(570.0, 98.0), 54, CORAL)
	_text("BEST %02d" % descent.best, Vector2(565.0, 145.0), 24, MUTED)
	draw_rect(Rect2(60.0, 178.0, 600.0, 13.0), Color("27466a"))
	draw_rect(Rect2(60.0, 178.0, 600.0 * descent.charge, 13.0), CYAN)
	_text("DRAG TO STEER", Vector2(60.0, 1254.0), 28, WHITE)
	_text("Find the open space.", Vector2(60.0, 1300.0), 24, MUTED)
	draw_rect(SHIFT_BUTTON.grow(8.0), Color(CYAN, 0.10 if not descent.slow else 0.24))
	draw_rect(SHIFT_BUTTON, CYAN, false, 4.0)
	_text("SHIFT TIME", Vector2(425.0, 1278.0), 31, CYAN)
	_text("SLOW" if descent.slow else "READY", Vector2(479.0, 1309.0), 19, MUTED)


func _draw_overlay() -> void:
	draw_rect(Rect2(50.0, 540.0, 620.0, 350.0), Color("112544"))
	draw_rect(Rect2(50.0, 540.0, 620.0, 350.0), CYAN, false, 3.0)
	if descent.mode == Descent.Mode.READY:
		_text("FALL THROUGH", Vector2(90.0, 632.0), 48, WHITE)
		_text("Drag to find a gate's opening.", Vector2(90.0, 706.0), 29, MUTED)
		_text("Shift time when you need space.", Vector2(90.0, 755.0), 29, MUTED)
		_text("TAP TO START", Vector2(90.0, 838.0), 33, CORAL)
	else:
		_text("SIGNAL LOST", Vector2(90.0, 632.0), 48, WHITE)
		_text("You cleared %d gates." % descent.score, Vector2(90.0, 707.0), 29, MUTED)
		_text("TAP TO DIVE AGAIN", Vector2(90.0, 836.0), 32, CORAL)


func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
