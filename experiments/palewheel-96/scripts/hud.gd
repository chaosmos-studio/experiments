class_name PalewheelHud
extends CanvasLayer

signal begin_pressed
signal pause_pressed
signal jump_pressed
signal jump_released
signal shift_pressed(step: int)
signal move_pressed(axis: float)

const INK: Color = Color("17142b")
const PAPER: Color = Color("fff0bc")
const CYAN: Color = Color("51d7d0")
const CORAL: Color = Color("eaa250")
const FONT: FontFile = preload("res://assets/fonts/LiberationMono-Bold.ttf")

var root: Control
var title_label: Label
var progress_label: Label
var gravity_label: Label
var hint_label: Label
var hint_back: Panel
var panel: ColorRect
var panel_title: Label
var panel_body: Label
var panel_button: TextureButton
var panel_button_label: Label
var extra_touches: Dictionary[int, String] = {}
var regular_font: FontVariation
var heavy_font: FontVariation


func _ready() -> void:
	layer = 1
	regular_font = _font(650)
	heavy_font = _font(850)
	root = Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var status: Panel = _panel(Rect2(54, 25, 760, 96), Color("211c37", 0.94), 0, 4)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label = _label(Vector2(82, 30), Vector2(700, 49), 33, PAPER, true)
	progress_label = _label(Vector2(84, 76), Vector2(685, 34), 26, CORAL)
	var gravity_panel: Panel = _panel(Rect2(1418, 25, 352, 82), Color("211c37", 0.94), 0, 4)
	gravity_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gravity_label = _label(Vector2(1432, 34), Vector2(317, 60), 27, PAPER, true)
	gravity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_art_button("res://assets/ui/retro_pause.svg", Rect2(1801, 28, 78, 78), func() -> void: pause_pressed.emit(), Callable())
	hint_back = _panel(Rect2(515, 143, 890, 56), INK, 0, 3)
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label = _label(Vector2(535, 142), Vector2(850, 58), 30, PAPER, true)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if DisplayServer.is_touchscreen_available():
		_art_button("res://assets/ui/retro_left.svg", Rect2(54, 906, 150, 130), func() -> void: move_pressed.emit(-1.0), func() -> void: move_pressed.emit(0.0))
		_art_button("res://assets/ui/retro_right.svg", Rect2(215, 906, 150, 130), func() -> void: move_pressed.emit(1.0), func() -> void: move_pressed.emit(0.0))
		_art_button("res://assets/ui/retro_jump.svg", Rect2(1505, 886, 165, 150), func() -> void: jump_pressed.emit(), func() -> void: jump_released.emit())
		_art_button("res://assets/ui/retro_turn.svg", Rect2(1692, 886, 165, 150), func() -> void: shift_pressed.emit(1), Callable())
		_action_label("JUMP", Rect2(1505, 988, 165, 39))
		_action_label("TURN", Rect2(1692, 988, 165, 39))
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
	if Rect2(54, 906, 150, 130).has_point(point):
		return "left"
	if Rect2(215, 906, 150, 130).has_point(point):
		return "right"
	if Rect2(1505, 886, 165, 150).has_point(point):
		return "jump"
	if Rect2(1692, 886, 165, 150).has_point(point):
		return "turn"
	return ""


func _press_extra_control(control: String) -> void:
	match control:
		"left": move_pressed.emit(-1.0)
		"right": move_pressed.emit(1.0)
		"jump": jump_pressed.emit()
		"turn": shift_pressed.emit(1)


func _release_extra_control(control: String) -> void:
	if control == "left" or control == "right":
		move_pressed.emit(0.0)
	elif control == "jump":
		jump_released.emit()


func _font(weight: int) -> FontVariation:
	var value: FontVariation = FontVariation.new()
	value.base_font = FONT
	value.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	value.variation_embolden = 0.0 if weight < 800 else 0.35
	return value


func _style(color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("100d22", 0.78)
	style.shadow_size = 0
	style.shadow_offset = Vector2(7, 7)
	return style


func _panel(rect: Rect2, color: Color, radius: int, border_width: int) -> Panel:
	var value: Panel = Panel.new()
	value.position = rect.position
	value.size = rect.size
	value.add_theme_stylebox_override("panel", _style(color, radius, border_width))
	root.add_child(value)
	return value


func _label(pos: Vector2, extent: Vector2, size_px: int, color: Color, heavy: bool = false) -> Label:
	var value: Label = Label.new()
	value.position = pos
	value.size = extent
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_override("font", heavy_font if heavy else regular_font)
	value.add_theme_font_size_override("font_size", size_px)
	value.add_theme_color_override("font_color", color)
	root.add_child(value)
	return value


func _art_button(path: String, rect: Rect2, down: Callable, up: Callable) -> void:
	var button: TextureButton = TextureButton.new()
	button.texture_normal = load(path) as Texture2D
	button.texture_pressed = button.texture_normal
	button.texture_hover = button.texture_normal
	button.position = rect.position
	button.size = rect.size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.pivot_offset = rect.size * 0.5
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(down)
	button.button_down.connect(func() -> void: _animate_button(button, Vector2(0.91, 0.91), 0.06))
	button.button_up.connect(func() -> void: _animate_button(button, Vector2.ONE, 0.12))
	if up.is_valid():
		button.button_up.connect(up)
	root.add_child(button)


func _action_label(text_value: String, rect: Rect2) -> void:
	var label: Label = _label(rect.position, rect.size, 25, PAPER, true)
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _animate_button(button: TextureButton, target: Vector2, duration: float) -> void:
	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_panel() -> void:
	panel = ColorRect.new()
	panel.color = Color("100d22", 0.88)
	panel.size = Vector2(1920, 1080)
	root.add_child(panel)
	var card: Panel = Panel.new()
	card.position = Vector2(137, 160)
	card.size = Vector2(1020, 754)
	card.add_theme_stylebox_override("panel", _style(Color("2a2345"), 0, 8))
	panel.add_child(card)
	var stripe: ColorRect = ColorRect.new()
	stripe.position = Vector2(0, 0)
	stripe.size = Vector2(1020, 22)
	stripe.color = CYAN
	card.add_child(stripe)
	var kicker: Label = Label.new()
	kicker.position = Vector2(72, 53)
	kicker.size = Vector2(860, 48)
	kicker.text = "1997  /  GRAVITY ENGINE"
	kicker.add_theme_font_override("font", heavy_font)
	kicker.add_theme_font_size_override("font_size", 25)
	kicker.add_theme_color_override("font_color", CORAL)
	card.add_child(kicker)
	panel_title = Label.new()
	panel_title.position = Vector2(70, 115)
	panel_title.size = Vector2(900, 138)
	panel_title.add_theme_font_override("font", heavy_font)
	panel_title.add_theme_font_size_override("font_size", 103)
	panel_title.add_theme_color_override("font_color", PAPER)
	card.add_child(panel_title)
	var rule: ColorRect = ColorRect.new()
	rule.position = Vector2(73, 258)
	rule.size = Vector2(800, 7)
	rule.color = CORAL
	card.add_child(rule)
	panel_body = Label.new()
	panel_body.position = Vector2(74, 303)
	panel_body.size = Vector2(810, 255)
	panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_theme_font_override("font", regular_font)
	panel_body.add_theme_font_size_override("font_size", 33)
	panel_body.add_theme_color_override("font_color", PAPER)
	card.add_child(panel_body)
	panel_button = TextureButton.new()
	panel_button.position = Vector2(72, 604)
	panel_button.size = Vector2(500, 100)
	panel_button.texture_normal = preload("res://assets/ui/retro_action.svg")
	panel_button.texture_hover = panel_button.texture_normal
	panel_button.texture_pressed = panel_button.texture_normal
	panel_button.ignore_texture_size = true
	panel_button.stretch_mode = TextureButton.STRETCH_SCALE
	panel_button.pivot_offset = panel_button.size * 0.5
	panel_button.focus_mode = Control.FOCUS_ALL
	panel_button.pressed.connect(func() -> void: begin_pressed.emit())
	panel_button.button_down.connect(func() -> void: _animate_button(panel_button, Vector2(0.96, 0.96), 0.06))
	panel_button.button_up.connect(func() -> void: _animate_button(panel_button, Vector2.ONE, 0.12))
	card.add_child(panel_button)
	panel_button_label = Label.new()
	panel_button_label.position = Vector2(48, 26)
	panel_button_label.size = Vector2(340, 57)
	panel_button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel_button_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_button_label.add_theme_font_override("font", heavy_font)
	panel_button_label.add_theme_font_size_override("font_size", 38)
	panel_button_label.add_theme_color_override("font_color", INK)
	panel_button.add_child(panel_button_label)
	var art_panel: Panel = Panel.new()
	art_panel.position = Vector2(1210, 180)
	art_panel.size = Vector2(560, 720)
	art_panel.add_theme_stylebox_override("panel", _style(Color("15132e"), 0, 8))
	panel.add_child(art_panel)
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = preload("res://assets/art/retro_idle.png")
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.position = Vector2(1240, 196)
	portrait.size = Vector2(500, 680)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait)


func show_panel(title: String, body: String, button: String) -> void:
	panel.visible = true
	panel_title.text = title
	panel_body.text = body
	panel_button_label.text = button
	panel_button.grab_focus()


func hide_panel() -> void:
	panel.visible = false


func set_hint(text: String) -> void:
	hint_label.text = text
	hint_label.modulate.a = 1.0
	hint_back.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.6)
	tween.parallel().tween_property(hint_back, "modulate:a", 0.0, 0.6)


func set_status(index: int, name: String, sparks: int, total_sparks: int, cargo_needed: bool, cargo_armed: bool, _time_text: String, gravity: Vector2) -> void:
	title_label.text = "%02d  /  %s" % [index + 1, name]
	var cargo_text: String = "    CARGO %s" % ("READY" if cargo_armed else "WAITING") if cargo_needed else ""
	progress_label.text = "CELLS %d / %d%s" % [sparks, total_sparks, cargo_text]
	var direction_name: String = "DOWN"
	if gravity == Vector2.LEFT:
		direction_name = "LEFT"
	elif gravity == Vector2.UP:
		direction_name = "UP"
	elif gravity == Vector2.RIGHT:
		direction_name = "RIGHT"
	gravity_label.text = "GRAVITY  /  " + direction_name
