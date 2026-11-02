extends Control

const Model: GDScript = preload("res://scripts/handover_model.gd")
const GREENHOUSE: Texture2D = preload("res://assets/art/greenhouse.png")
const CREW_ART: Texture2D = preload("res://assets/art/crew.png")
const FONT: Font = preload("res://assets/fonts/Outfit-Medium.ttf")
const FONT_LIGHT: Font = preload("res://assets/fonts/Outfit-Light.ttf")
const SHIFT_SFX: AudioStreamWAV = preload("res://assets/audio/sfx/shift.wav")
const TASK_SFX: AudioStreamWAV = preload("res://assets/audio/sfx/task.wav")
const COMPLETE_SFX: AudioStreamWAV = preload("res://assets/audio/sfx/complete.wav")
const W: float = 1920.0
const H: float = 1080.0
const INK: Color = Color("243b36")
const MUTED: Color = Color("54716a")
const CREAM: Color = Color("fff9e9")
const GOLD: Color = Color("d38b47")
const GREEN: Color = Color("5c8d6e")
const CORAL: Color = Color("c87059")
const CREW_COLORS: Array[Color] = [Color("c87059"), Color("5d9079"), Color("d5a448")]
const STATION_X: Array[float] = [560.0, 960.0, 1360.0]
const CARD_X: Array[float] = [450.0, 960.0, 1470.0]

var model: HandoverModel = Model.new()
var message: String = "Tap a machine, then shift to another caretaker."
var message_color: Color = INK
var _scale: float = 1.0
var _origin: Vector2 = Vector2.ZERO
var _sfx: AudioStreamPlayer
var _last_tap_ms: int = -1000
var _last_tap_position: Vector2 = Vector2(-10000.0, -10000.0)

func _ready() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.volume_db = -10.0
	add_child(_sfx)
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	_scale = minf(size.x / W, size.y / H)
	_origin = (size - Vector2(W, H) * _scale) * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), CREAM)
	draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
	draw_texture_rect(GREENHOUSE, Rect2(0.0, 0.0, W, H), false)
	draw_rect(Rect2(0.0, 0.0, W, H), Color(1.0, 0.973, 0.88, 0.10))
	_draw_scene()
	_draw_top()
	_draw_bottom()
	if model.cleared:
		_draw_clear()
	if model.finished:
		_draw_final()
	draw_set_transform(Vector2.ZERO)

func _draw_scene() -> void:
	var tasks: Array = Model.STAGES[model.stage]["tasks"]
	for index: int in range(tasks.size()):
		var x: float = _station_x(index, tasks.size())
		var owner: int = int(Model.STAGES[model.stage]["owners"][index])
		var active: bool = model.assignments[owner] == index
		var prerequisite: int = int(Model.STAGES[model.stage]["requires"][index])
		var unlocked: bool = prerequisite < 0 or model.assignments[int(Model.STAGES[model.stage]["owners"][prerequisite])] == prerequisite
		_draw_station(Vector2(x, 548.0), str(tasks[index]), owner, active, unlocked, index)
	for actor: int in range(3):
		var assigned: int = model.assignments[actor]
		var x: float = _station_x(assigned, tasks.size()) if assigned >= 0 else CARD_X[actor]
		var source: Rect2 = Rect2(float(actor * 512), 0.0, 512.0, 1024.0)
		draw_texture_rect_region(CREW_ART, Rect2(x - 84.0, 630.0, 168.0, 336.0), source)
		if actor == model.selected and not model.cleared:
			draw_arc(Vector2(x, 944.0), 72.0, 0.0, TAU, 48, CREW_COLORS[actor], 7.0, true)

func _draw_station(center: Vector2, label: String, owner: int, active: bool, unlocked: bool, index: int) -> void:
	var tint: Color = GREEN if active else CREW_COLORS[owner]
	var fill: Color = Color("eaf5e8") if active else Color("fff9eb")
	if not unlocked:
		fill = Color("e6e6da")
		tint = MUTED
	_panel(Rect2(center.x - 170.0, center.y - 123.0, 340.0, 173.0), fill, tint, 26)
	draw_circle(center + Vector2(0.0, -53.0), 30.0, tint)
	_symbol(center + Vector2(0.0, -53.0), index)
	_label(label, center + Vector2(-153.0, -4.0), 32, INK, 306.0, HORIZONTAL_ALIGNMENT_CENTER)
	_label("WORKING" if active else ("WAITING" if not unlocked else "TAP TO ASSIGN"), center + Vector2(-153.0, 33.0), 22, tint, 306.0, HORIZONTAL_ALIGNMENT_CENTER)

func _symbol(center: Vector2, index: int) -> void:
	if index == 0:
		draw_arc(center, 15.0, -2.3, 2.1, 20, CREAM, 4.0, true)
		draw_line(center + Vector2(9.0, 10.0), center + Vector2(16.0, 18.0), CREAM, 4.0, true)
	elif index == 1:
		draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), CREAM, 5.0, true)
		draw_line(center + Vector2(0.0, -18.0), center + Vector2(0.0, 18.0), CREAM, 5.0, true)
	else:
		var points: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -21.0), center + Vector2(19.0, 16.0), center + Vector2(-19.0, 16.0)])
		draw_colored_polygon(points, CREAM)

func _draw_top() -> void:
	_panel(Rect2(50.0, 42.0, 1820.0, 224.0), Color("fffaf0e9"), Color("d6b795"), 34)
	_label("HANDOVER", Vector2(90.0, 110.0), 30, CORAL)
	_label("%02d  /  03" % (model.stage + 1), Vector2(1620.0, 110.0), 29, MUTED, 180.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(str(Model.STAGES[model.stage]["title"]), Vector2(90.0, 178.0), 62, INK)
	_label(str(Model.STAGES[model.stage]["line"]), Vector2(93.0, 225.0), 30, MUTED)
	draw_line(Vector2(1260.0, 204.0), Vector2(1802.0, 204.0), Color("d7c6a6"), 2.0, true)
	for index: int in range(3):
		draw_circle(Vector2(1330.0 + 194.0 * index, 204.0), 10.0, GOLD if index <= model.stage else Color("ddd7c6"))

func _draw_bottom() -> void:
	_panel(Rect2(48.0, 867.0, 1824.0, 178.0), Color("fffbf1f5"), Color("d8c4aa"), 32)
	for actor: int in range(3):
		var rect: Rect2 = Rect2(CARD_X[actor] - 205.0, 890.0, 410.0, 128.0)
		var active: bool = model.selected == actor
		_panel(rect, Color("ffffff") if active else Color("f6f0e3"), CREW_COLORS[actor] if active else Color("d8cbbb"), 24)
		draw_circle(Vector2(rect.position.x + 44.0, 934.0), 20.0, CREW_COLORS[actor])
		_label(str(actor + 1), Vector2(rect.position.x + 34.0, 943.0), 25, CREAM)
		_label(Model.CREW[actor], Vector2(rect.position.x + 78.0, 943.0), 38, INK)
		var state: String = "AT WORK" if model.assignments[actor] >= 0 else ("SELECTED" if active else "SHIFT HERE")
		_label(state, Vector2(rect.position.x + 79.0, 986.0), 23, CREW_COLORS[actor])
	_panel(Rect2(177.0, 775.0, 1566.0, 74.0), Color("fffaf0e9"), Color("d8c4aa"), 24)
	_label(message, Vector2(215.0, 825.0), 30, message_color, 1488.0, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_clear() -> void:
	_panel(Rect2(503.0, 320.0, 914.0, 412.0), Color("fff9eafa"), GOLD, 40)
	draw_circle(Vector2(960.0, 408.0), 37.0, GOLD)
	draw_circle(Vector2(960.0, 408.0), 23.0, CREAM)
	_label(str(Model.STAGES[model.stage]["done"]), Vector2(553.0, 505.0), 49, INK, 814.0, HORIZONTAL_ALIGNMENT_CENTER)
	_label("Each caretaker kept their promise.", Vector2(553.0, 561.0), 30, MUTED, 814.0, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(748.0, 620.0, 424.0, 82.0), GREEN, GREEN, 25)
	_label("CONTINUE", Vector2(769.0, 673.0), 35, CREAM, 382.0, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_final() -> void:
	draw_rect(Rect2(0.0, 0.0, W, H), Color("fff1ca73"))
	_panel(Rect2(380.0, 210.0, 1160.0, 616.0), Color("fffaf0f5"), GOLD, 44)
	_label("WE MADE MORNING", Vector2(460.0, 365.0), 81, INK, 1000.0, HORIZONTAL_ALIGNMENT_CENTER)
	_label("The greenhouse is awake because everyone stayed.", Vector2(460.0, 449.0), 38, MUTED, 1000.0, HORIZONTAL_ALIGNMENT_CENTER)
	_label("%d shifts, one sunrise." % model.shifts, Vector2(460.0, 515.0), 31, CORAL, 1000.0, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(737.0, 615.0, 446.0, 96.0), GREEN, GREEN, 26)
	_label("PLAY AGAIN", Vector2(757.0, 679.0), 39, CREAM, 406.0, HORIZONTAL_ALIGNMENT_CENTER)

func _panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	draw_style_box(box, rect)

func _label(value: String, position: Vector2, font_size: int, color: Color, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font: Font = FONT_LIGHT if font_size < 32 else FONT
	draw_string(font, position, value, alignment, width, font_size, color)

func _station_x(index: int, count: int) -> float:
	if count == 2:
		return 700.0 + 520.0 * index
	return STATION_X[index]

func _gui_input(event: InputEvent) -> void:
	var point: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		point = mouse.position
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if not touch.pressed:
			return
		point = touch.position
	else:
		return
	var logical_point: Vector2 = (point - _origin) / _scale
	var now: int = Time.get_ticks_msec()
	if now - _last_tap_ms < 500 and logical_point.distance_to(_last_tap_position) < 24.0:
		accept_event()
		return
	_last_tap_ms = now
	_last_tap_position = logical_point
	_handle_tap(logical_point)
	accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		if key.keycode >= KEY_1 and key.keycode <= KEY_3:
			model.select_worker(key.keycode - KEY_1)
			_update_message()
		elif key.keycode == KEY_R:
			model.restart()
			_update_message()
		queue_redraw()

func _handle_tap(point: Vector2) -> void:
	if model.finished:
		if Rect2(737.0, 615.0, 446.0, 96.0).has_point(point):
			model.restart()
			_update_message()
			_play_sfx(SHIFT_SFX)
		queue_redraw()
		return
	if model.cleared:
		if Rect2(748.0, 620.0, 424.0, 82.0).has_point(point):
			model.advance()
			_update_message()
			_play_sfx(COMPLETE_SFX)
		queue_redraw()
		return
	for actor: int in range(3):
		if Rect2(CARD_X[actor] - 205.0, 890.0, 410.0, 128.0).has_point(point):
			model.select_worker(actor)
			_update_message()
			_play_sfx(SHIFT_SFX)
			queue_redraw()
			return
	var tasks: Array = Model.STAGES[model.stage]["tasks"]
	for index: int in range(tasks.size()):
		if Rect2(_station_x(index, tasks.size()) - 170.0, 425.0, 340.0, 173.0).has_point(point):
			var result: String = model.assign(index)
			_match_result(result, index)
			if result == "assigned":
				_play_sfx(TASK_SFX)
			elif result == "complete":
				_play_sfx(COMPLETE_SFX)
			queue_redraw()
			return

func _match_result(result: String, index: int) -> void:
	var owner: int = int(Model.STAGES[model.stage]["owners"][index])
	match result:
		"wrong_worker":
			message = "%s knows this machine. Shift to them." % Model.CREW[owner]
			message_color = CORAL
		"locked":
			message = "This needs the previous task to stay active."
			message_color = CORAL
		"assigned":
			message = "%s stays here. Shift and give someone else a task." % Model.CREW[model.selected]
			message_color = GREEN
		"complete":
			message = "The team did it together."
			message_color = GREEN

func _update_message() -> void:
	message = "%s is ready. Tap a machine." % Model.CREW[model.selected]
	message_color = INK

func _play_sfx(sound: AudioStreamWAV) -> void:
	if _sfx == null or not _sfx.is_inside_tree():
		return
	_sfx.stream = sound
	_sfx.play()
