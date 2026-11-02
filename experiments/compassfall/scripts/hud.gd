class_name CompassHud
extends CanvasLayer

signal begin_pressed
signal pause_pressed
signal jump_pressed
signal shift_pressed(step: int)
signal move_pressed(axis: float)

var root: Control
var title_label: Label
var progress_label: Label
var gravity_label: Label
var hint_label: Label
var panel: ColorRect
var panel_title: Label
var panel_body: Label
var panel_button: Button
var extra_touches: Dictionary[int, String] = {}


func _ready() -> void:
	layer = 1
	root = Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var bar: ColorRect = ColorRect.new()
	bar.position = Vector2(110, 25)
	bar.size = Vector2(1700, 106)
	bar.color = Color("173e49", 0.92)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	title_label = _label(Vector2(150, 35), Vector2(1130, 52), 36, Color("fff6df"))
	progress_label = _label(Vector2(150, 82), Vector2(1280, 40), 25, Color("ccebe0"))
	gravity_label = _label(Vector2(1450, 45), Vector2(330, 60), 34, Color("ffda91"))
	gravity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label = _label(Vector2(270, 160), Vector2(1380, 64), 28, Color("31565e"))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button("LEFT", Vector2(54, 943), Vector2(124, 104), Color("246370"), func() -> void: move_pressed.emit(-1.0), func() -> void: move_pressed.emit(0.0))
	_button("RIGHT", Vector2(193, 943), Vector2(124, 104), Color("246370"), func() -> void: move_pressed.emit(1.0), func() -> void: move_pressed.emit(0.0))
	_button("JUMP", Vector2(1410, 943), Vector2(150, 104), Color("e28d59"), func() -> void: jump_pressed.emit())
	_button("CCW", Vector2(1575, 943), Vector2(124, 104), Color("3e9d98"), func() -> void: shift_pressed.emit(-1))
	_button("CW", Vector2(1713, 943), Vector2(124, 104), Color("3e9d98"), func() -> void: shift_pressed.emit(1))
	_button("||", Vector2(1831, 39), Vector2(66, 66), Color("315762"), func() -> void: pause_pressed.emit())
	var instructions: Label = _label(Vector2(400, 965), Vector2(940, 42), 20, Color("49656a"))
	instructions.text = "A / D move     SPACE jump     Q / E shift     R restart"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_panel()


func _input(event: InputEvent) -> void:
	if panel.visible:
		return
	if event is InputEventScreenTouch and event.index > 0:
		if event.pressed:
			var control: String = _touch_control_at(event.position)
			extra_touches[event.index] = control
			_press_extra_control(control)
		else:
			_release_extra_control(extra_touches.get(event.index, ""))
			extra_touches.erase(event.index)
	elif event is InputEventScreenDrag and event.index > 0:
		var previous: String = extra_touches.get(event.index, "")
		var next: String = _touch_control_at(event.position)
		if previous != next:
			_release_extra_control(previous)
			extra_touches[event.index] = next
			_press_extra_control(next)


func _touch_control_at(point: Vector2) -> String:
	if Rect2(54, 943, 124, 104).has_point(point):
		return "left"
	if Rect2(193, 943, 124, 104).has_point(point):
		return "right"
	if Rect2(1410, 943, 150, 104).has_point(point):
		return "jump"
	if Rect2(1575, 943, 124, 104).has_point(point):
		return "ccw"
	if Rect2(1713, 943, 124, 104).has_point(point):
		return "cw"
	return ""


func _press_extra_control(control: String) -> void:
	match control:
		"left": move_pressed.emit(-1.0)
		"right": move_pressed.emit(1.0)
		"jump": jump_pressed.emit()
		"ccw": shift_pressed.emit(-1)
		"cw": shift_pressed.emit(1)


func _release_extra_control(control: String) -> void:
	if control == "left" or control == "right":
		move_pressed.emit(0.0)


func _label(pos: Vector2, extent: Vector2, size_px: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.position = pos
	label.size = extent
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label


func _button(text: String, pos: Vector2, extent: Vector2, color: Color, down: Callable, up: Callable = Callable()) -> void:
	var button: Button = Button.new()
	button.text = text
	button.position = pos
	button.size = extent
	button.add_theme_font_size_override("font_size", 36 if text.length() < 3 else 27)
	button.add_theme_color_override("font_color", Color("fffaf0"))
	button.add_theme_color_override("font_pressed_color", Color("fffaf0"))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(26)
	button.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.17)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.button_down.connect(down)
	if up.is_valid():
		button.button_up.connect(up)
	root.add_child(button)


func _build_panel() -> void:
	panel = ColorRect.new()
	panel.color = Color("f7f2e6", 0.96)
	panel.size = Vector2(1920, 1080)
	root.add_child(panel)
	var card: ColorRect = ColorRect.new()
	card.color = Color("dfebe0")
	card.position = Vector2(355, 182)
	card.size = Vector2(1210, 690)
	panel.add_child(card)
	panel_title = Label.new()
	panel_title.position = Vector2(88, 65)
	panel_title.size = Vector2(1034, 116)
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_title.add_theme_font_size_override("font_size", 70)
	panel_title.add_theme_color_override("font_color", Color("194851"))
	card.add_child(panel_title)
	panel_body = Label.new()
	panel_body.position = Vector2(130, 196)
	panel_body.size = Vector2(950, 290)
	panel_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_theme_font_size_override("font_size", 31)
	panel_body.add_theme_color_override("font_color", Color("3b5f62"))
	card.add_child(panel_body)
	panel_button = Button.new()
	panel_button.position = Vector2(425, 537)
	panel_button.size = Vector2(360, 104)
	panel_button.add_theme_font_size_override("font_size", 34)
	panel_button.add_theme_color_override("font_color", Color("fffaf0"))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("e1845c")
	style.set_corner_radius_all(28)
	panel_button.add_theme_stylebox_override("normal", style)
	panel_button.add_theme_stylebox_override("hover", style)
	panel_button.pressed.connect(func() -> void: begin_pressed.emit())
	card.add_child(panel_button)


func show_panel(title: String, body: String, button: String) -> void:
	panel.visible = true
	panel_title.text = title
	panel_body.text = body
	panel_button.text = button


func hide_panel() -> void:
	panel.visible = false


func set_hint(text: String) -> void:
	hint_label.text = text
	hint_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.6)


func set_status(index: int, name: String, sparks: int, total_sparks: int, cargo_needed: bool, cargo_armed: bool, time_text: String, gravity: Vector2) -> void:
	title_label.text = "%02d  /  %s" % [index + 1, name]
	var cargo_text: String = "  •  CARGO %s" % ("ARMED" if cargo_armed else "WAITING") if cargo_needed else ""
	progress_label.text = "SPARKS %d / %d%s     •     %s" % [sparks, total_sparks, cargo_text, time_text]
	var direction_name: String = "DOWN"
	if gravity == Vector2.LEFT:
		direction_name = "LEFT"
	elif gravity == Vector2.UP:
		direction_name = "UP"
	elif gravity == Vector2.RIGHT:
		direction_name = "RIGHT"
	gravity_label.text = "GRAVITY  " + direction_name
