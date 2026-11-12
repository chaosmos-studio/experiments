extends CanvasLayer

signal start_requested
signal primary_requested
signal secondary_requested
signal dash_requested
signal touch_axis_changed(axis: Vector2)

const DISPLAY_FONT := preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BODY_FONT := preload("res://assets/fonts/Baloo2.ttf")
const INK := Color("2b3129")
const CREAM := Color("fff3d6")
const GOLD := Color("efbd64")

var title := "ACTION LAB"
var description := ""
var controls := ""
var primary_name := "ACT"
var secondary_name := "SHIFT"
var root: Control
var menu: ColorRect
var title_label: Label
var description_label: Label
var start_button: Button
var hud: Control
var left_label: Label
var right_label: Label
var toast_label: Label
var touch_layer: Control
var toast_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_menu()
	_build_hud()
	_build_touch()
	show_intro()


func _style(color: Color, border: Color = GOLD) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.04, 0.07, 0.05, 0.39)
	style.shadow_size = 12
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	return style


func _label(value: String, size: int, color: Color, display := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", DISPLAY_FONT if display else BODY_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(125, 64)
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", _style(color, color.darkened(0.28)))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.12), color.darkened(0.22)))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), color.darkened(0.30)))
	return button


func _build_menu() -> void:
	menu = ColorRect.new()
	menu.color = Color(0.10, 0.16, 0.13, 0.84)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(menu)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 470)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -235)
	panel.add_theme_stylebox_override("panel", _style(Color("31473d")))
	menu.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(_label("CHAOSMOS · ACTION LAB", 18, GOLD))
	title_label = _label(title, 68, CREAM, true)
	column.add_child(title_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/hero_walk.png")
	atlas.region = Rect2(0, 0, 192, 192)
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(160, 160)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	description_label = _label(description, 24, CREAM)
	description_label.custom_minimum_size.x = 390
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(description_label)
	column.add_child(_label(controls, 17, Color("d2ddc6")))
	start_button = _button("PLAY", GOLD)
	start_button.custom_minimum_size.y = 75
	start_button.pressed.connect(func() -> void: start_requested.emit())
	column.add_child(start_button)
	start_button.grab_focus.call_deferred()


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var left := PanelContainer.new()
	left.position = Vector2(20, 20)
	left.custom_minimum_size = Vector2(250, 77)
	left.add_theme_stylebox_override("panel", _style(Color("263d32", 0.95)))
	hud.add_child(left)
	left_label = _label("", 29, CREAM, true)
	left.add_child(left_label)
	var right := PanelContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-300, 20)
	right.custom_minimum_size = Vector2(280, 77)
	right.add_theme_stylebox_override("panel", _style(Color("263d32", 0.95)))
	hud.add_child(right)
	right_label = _label("", 27, CREAM, true)
	right.add_child(right_label)
	toast_label = _label("", 28, CREAM, true)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-260, 116)
	toast_label.custom_minimum_size.x = 520
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	toast_label.add_theme_constant_override("shadow_offset_x", 2)
	toast_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(toast_label)


func _build_touch() -> void:
	touch_layer = Control.new()
	touch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(touch_layer)
	var pad: Control = preload("res://scripts/touch_pad.gd").new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pad.position = Vector2(16, -205)
	pad.custom_minimum_size = Vector2(185, 185)
	pad.axis_changed.connect(func(axis: Vector2) -> void: touch_axis_changed.emit(axis))
	touch_layer.add_child(pad)
	var actions := HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-423, -115)
	actions.add_theme_constant_override("separation", 8)
	touch_layer.add_child(actions)
	var primary := _button(primary_name, Color("e7a36e"))
	primary.pressed.connect(func() -> void: primary_requested.emit())
	actions.add_child(primary)
	var secondary := _button(secondary_name, Color("b5d481"))
	secondary.pressed.connect(func() -> void: secondary_requested.emit())
	actions.add_child(secondary)
	var dash := _button("DASH", Color("89c4d3"))
	dash.pressed.connect(func() -> void: dash_requested.emit())
	actions.add_child(dash)


func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_label.text = ""


func show_intro() -> void:
	menu.visible = true
	hud.visible = false
	touch_layer.visible = false


func show_play() -> void:
	menu.visible = false
	hud.visible = true
	touch_layer.visible = DisplayServer.is_touchscreen_available()


func show_result(won: bool, summary: String) -> void:
	menu.visible = true
	hud.visible = false
	touch_layer.visible = false
	title_label.text = "WELL DONE" if won else "TRY AGAIN"
	description_label.text = summary
	start_button.text = "PLAY AGAIN"
	start_button.grab_focus.call_deferred()


func update_status(left: String, right: String) -> void:
	left_label.text = left
	right_label.text = right


func toast(value: String) -> void:
	toast_label.text = value
	toast_time = 2.2
