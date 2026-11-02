extends Control

const Run = preload("res://scripts/run.gd")
const FONT: Font = preload("res://assets/fonts/Manrope.ttf")
const SHIFT_SOUND: AudioStream = preload("res://assets/audio/shift.wav")
const PASS_SOUND: AudioStream = preload("res://assets/audio/pass.wav")
const CRASH_SOUND: AudioStream = preload("res://assets/audio/crash.wav")
const NIGHT: Color = Color("090d23")
const WHITE: Color = Color("f5f7ff")
const MUTED: Color = Color("9aa7c4")
const GOLD: Color = Color("f9bd67")
const CYAN: Color = Color("7ce9db")
const PINK: Color = Color("f479ae")
const DESIGN: Vector2 = Vector2(720.0, 1440.0)

@onready var sound: AudioStreamPlayer = $Sound

var run: RefCounted = Run.new()
var clock: float = 0.0
var trail: Array[Vector2] = []
var trail_timer: float = 0.0
var flash: float = 0.0


func _ready() -> void:
	print("FLIPLINE_READY")
	queue_redraw()


func _exit_tree() -> void:
	if is_instance_valid(sound):
		sound.stop()
		sound.stream = null


func _process(delta: float) -> void:
	clock += delta
	flash = maxf(0.0, flash - delta * 2.7)
	if run.mode == Run.Mode.RUNNING:
		var previous_score: int = run.score
		run.step(delta)
		if run.score > previous_score:
			_play(PASS_SOUND)
			print("FLIPLINE_SCORE %d" % run.score)
		if run.mode == Run.Mode.CRASHED:
			flash = 1.0
			_play(CRASH_SOUND)
			print("FLIPLINE_CRASH %d" % run.score)
		trail_timer += delta
		if trail_timer >= 0.035:
			trail_timer = 0.0
			trail.push_front(Vector2(Run.PLAYER_X, run.player_y))
			if trail.size() > 16:
				trail.pop_back()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_act()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_act()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shift_gravity"):
		_act()
	elif event.is_action_pressed("retry") and run.mode == Run.Mode.CRASHED:
		_act()


func _act() -> void:
	if run.mode == Run.Mode.RUNNING:
		if run.shift():
			flash = 0.35
			_play(SHIFT_SOUND)
			print("FLIPLINE_SHIFT %d" % run.side)
	else:
		run.start()
		trail.clear()
		flash = 0.0
		print("FLIPLINE_START")
	queue_redraw()


func _play(stream: AudioStream) -> void:
	if DisplayServer.get_name() == "headless":
		return
	sound.stop()
	sound.stream = stream
	sound.play()


func _draw() -> void:
	var scale_factor: float = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	var offset: Vector2 = (size - DESIGN * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(Vector2.ZERO, DESIGN), NIGHT)
	_draw_sky()
	_draw_city()
	_draw_rails()
	for gate: RefCounted in run.gates:
		_draw_gate(gate)
	_draw_runner()
	_draw_hud()
	if run.mode != Run.Mode.RUNNING:
		_draw_overlay()
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, DESIGN), Color(1.0, 1.0, 1.0, flash * 0.10))
	draw_set_transform(Vector2.ZERO)


func _draw_sky() -> void:
	for index: int in 58:
		var x: float = float((index * 137 + 31) % 674) + 23.0
		var y: float = float((index * 197 + 17) % 940) + 190.0
		var twinkle: float = 0.25 + 0.35 * (0.5 + 0.5 * sin(clock * 1.6 + float(index)))
		draw_circle(Vector2(x, y), 1.8 if index % 4 else 2.8, Color(0.79, 0.88, 1.0, twinkle))
	for index: int in 10:
		var x: float = fposmod(float(index) * 108.0 - run.distance * 0.25, 1080.0) - 150.0
		draw_line(Vector2(x, 410.0), Vector2(x + 42.0, 410.0), Color(CYAN, 0.20), 3.0)
		draw_line(Vector2(x, 1030.0), Vector2(x + 42.0, 1030.0), Color(GOLD, 0.20), 3.0)


func _draw_city() -> void:
	for layer: int in 2:
		var speed: float = 0.06 if layer == 0 else 0.15
		var base_y: float = 1150.0 if layer == 0 else 1190.0
		var color: Color = Color("151f42") if layer == 0 else Color("1c2b52")
		for index: int in 12:
			var x: float = float(index) * 86.0 - fposmod(run.distance * speed, 86.0) - 86.0
			var height: float = 65.0 + float((index * 53 + layer * 29) % 145)
			draw_rect(Rect2(x, base_y - height, 64.0, height + 250.0), color)
			if layer == 1:
				for window: int in 3:
					draw_rect(Rect2(x + 13.0 + float(window % 2) * 25.0, base_y - height + 20.0 + float(window) * 31.0, 7.0, 10.0), Color(GOLD, 0.35))


func _draw_rails() -> void:
	for y: float in [420.0, 1020.0]:
		draw_line(Vector2(0.0, y), Vector2(720.0, y), Color(CYAN, 0.10), 30.0)
		draw_line(Vector2(0.0, y), Vector2(720.0, y), CYAN if y < 700.0 else GOLD, 4.0)
		for index: int in 9:
			var x: float = fposmod(float(index) * 120.0 - run.distance * 0.55, 1080.0) - 150.0
			draw_line(Vector2(x, y - 10.0), Vector2(x + 30.0, y - 10.0), Color(WHITE, 0.42), 4.0)


func _draw_gate(gate: RefCounted) -> void:
	var top: float = 330.0 if gate.side == 0 else 730.0
	var rect: Rect2 = Rect2(gate.x - Run.GATE_WIDTH * 0.5, top, Run.GATE_WIDTH, 380.0)
	draw_rect(rect.grow(18.0), Color(PINK, 0.09))
	draw_rect(rect.grow(8.0), Color(PINK, 0.20))
	draw_rect(rect, PINK)
	draw_rect(rect.grow(-9.0), Color("672449"))
	for index: int in 8:
		var stripe_y: float = top + 14.0 + float(index) * 48.0
		draw_line(Vector2(gate.x - 18.0, stripe_y), Vector2(gate.x + 18.0, stripe_y - 16.0), Color(WHITE, 0.45), 3.0)


func _draw_runner() -> void:
	for index: int in trail.size():
		var point: Vector2 = trail[index] - Vector2(float(index) * 15.0, 0.0)
		var alpha: float = 0.28 * (1.0 - float(index) / float(trail.size()))
		draw_circle(point, 18.0 - float(index) * 0.65, Color(CYAN, alpha))
	var point: Vector2 = Vector2(Run.PLAYER_X, run.player_y)
	draw_circle(point, 48.0, Color(CYAN, 0.09))
	draw_circle(point, 31.0, Color(CYAN, 0.24))
	draw_colored_polygon(PackedVector2Array([point + Vector2(31.0, 0.0), point + Vector2(-22.0, -21.0), point + Vector2(-13.0, 0.0), point + Vector2(-22.0, 21.0)]), WHITE)
	draw_circle(point + Vector2(-1.0, 0.0), 7.0, GOLD)


func _draw_hud() -> void:
	_text("FLIPLINE", Vector2(58.0, 105.0), 50, WHITE)
	_text("SHIFT THE PULL", Vector2(60.0, 157.0), 26, CYAN)
	_text("%02d" % run.score, Vector2(570.0, 105.0), 54, GOLD)
	_text("BEST %02d" % run.best, Vector2(565.0, 150.0), 24, MUTED)
	_text("TAP TO FLIP", Vector2(60.0, 1310.0), 29, WHITE)
	_text("Avoid the pink barriers.", Vector2(60.0, 1352.0), 24, MUTED)
	var pull_label: String = "PULL: DOWN" if run.side == 1 else "PULL: UP"
	_text(pull_label, Vector2(470.0, 1310.0), 26, GOLD if run.side == 1 else CYAN)


func _draw_overlay() -> void:
	draw_rect(Rect2(50.0, 535.0, 620.0, 336.0), Color("101a38"))
	draw_rect(Rect2(50.0, 535.0, 620.0, 336.0), CYAN, false, 3.0)
	if run.mode == Run.Mode.READY:
		_text("SHIFT GRAVITY", Vector2(92.0, 628.0), 48, WHITE)
		_text("One tap changes which rail pulls you.", Vector2(92.0, 697.0), 27, MUTED)
		_text("Slip past each glowing barrier.", Vector2(92.0, 744.0), 27, MUTED)
		_text("TAP TO START", Vector2(92.0, 823.0), 32, GOLD)
	else:
		_text("RUN OVER", Vector2(92.0, 628.0), 51, WHITE)
		_text("You passed %d barriers." % run.score, Vector2(92.0, 700.0), 29, MUTED)
		_text("TAP TO RUN AGAIN", Vector2(92.0, 812.0), 32, GOLD)


func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
