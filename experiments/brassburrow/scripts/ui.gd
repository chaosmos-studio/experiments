extends CanvasLayer

signal start_requested
signal attack_requested
signal dash_requested
signal build_requested
signal repair_requested
signal touch_axis_changed(axis: Vector2)

const DISPLAY_FONT := preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BODY_FONT := preload("res://assets/fonts/Baloo2.ttf")
const INK := Color("2b3129")
const CREAM := Color("fff3d6")
const GOLD := Color("efbd64")

var root: Control
var menu: ColorRect
var menu_title: Label
var menu_copy: Label
var menu_button: Button
var hud: Control
var hearth_label: Label
var player_label: Label
var scrap_label: Label
var wave_label: Label
var toast_label: Label
var touch_layer: Control
var toast_timer := 0.0


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


func _panel_style(color: Color, border: Color = Color("c8a76f")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(19)
	style.shadow_color = Color(0.06, 0.08, 0.05, 0.4)
	style.shadow_size = 10
	style.content_margin_left = 23
	style.content_margin_right = 23
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, color: Color, font_size: int = 29) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(132, 62)
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", _panel_style(color, color.darkened(0.29)))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.13), color.darkened(0.24)))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.14), color.darkened(0.35)))
	button.focus_mode = Control.FOCUS_ALL
	return button


func _build_menu() -> void:
	menu = ColorRect.new()
	menu.color = Color(0.10, 0.15, 0.12, 0.79)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(menu)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(575, 500)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-287, -250)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("344b3e"), GOLD))
	menu.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	column.add_child(_label("CHAOSMOS · ACTION LAB", BODY_FONT, 18, GOLD))
	menu_title = _label("BRASSBURROW", DISPLAY_FONT, 70, CREAM)
	column.add_child(menu_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/hero_walk.png")
	atlas.region = Rect2(0, 0, 192, 192)
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(145, 145)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	menu_copy = _label("Walk with the furnace.\nGather copper pods. Build seed cannons.\nKeep the beetles off your moving home.", BODY_FONT, 24, CREAM)
	menu_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_copy.custom_minimum_size.x = 310
	menu_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(menu_copy)
	column.add_child(_label("MOVE  WASD / ARROWS     STRIKE  J / CLICK     DASH  SPACE", BODY_FONT, 17, Color("d6dcbd")))
	column.add_child(_label("BUILD  K (5 COPPER)     PATCH  R (3 COPPER)", BODY_FONT, 17, Color("d6dcbd")))
	menu_button = _button("START THE MARCH", GOLD, 30)
	menu_button.custom_minimum_size.y = 70
	menu_button.pressed.connect(func() -> void: start_requested.emit())
	column.add_child(menu_button)
	column.add_child(_label("Original animated figures, built and rendered for this game.", BODY_FONT, 16, Color("bacab1")))
	menu_button.grab_focus.call_deferred()


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var left := PanelContainer.new()
	left.position = Vector2(22, 20)
	left.custom_minimum_size = Vector2(300, 110)
	left.add_theme_stylebox_override("panel", _panel_style(Color("2a3d32", 0.94)))
	hud.add_child(left)
	var left_col := VBoxContainer.new()
	left.add_child(left_col)
	left_col.add_child(_label("THE WALKING HEARTH", BODY_FONT, 16, GOLD))
	hearth_label = _label("200 / 200", DISPLAY_FONT, 33, CREAM)
	left_col.add_child(hearth_label)
	player_label = _label("PIP  100", BODY_FONT, 18, Color("c6e6c9"))
	left_col.add_child(player_label)
	var right := PanelContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-310, 20)
	right.custom_minimum_size = Vector2(288, 110)
	right.add_theme_stylebox_override("panel", _panel_style(Color("2a3d32", 0.94)))
	hud.add_child(right)
	var right_col := VBoxContainer.new()
	right.add_child(right_col)
	wave_label = _label("MEADOW · FIRST WAVE", BODY_FONT, 17, GOLD)
	right_col.add_child(wave_label)
	scrap_label = _label("COPPER  5", DISPLAY_FONT, 32, CREAM)
	right_col.add_child(scrap_label)
	toast_label = _label("", DISPLAY_FONT, 27, CREAM)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-230, 144)
	toast_label.custom_minimum_size.x = 460
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	toast_label.add_theme_constant_override("shadow_offset_x", 2)
	toast_label.add_theme_constant_override("shadow_offset_y", 3)
	hud.add_child(toast_label)
	hud.visible = false


func _build_touch() -> void:
	touch_layer = Control.new()
	touch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(touch_layer)
	var pad: Control = preload("res://scripts/touch_pad.gd").new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pad.position = Vector2(17, -212)
	pad.custom_minimum_size = Vector2(185, 185)
	pad.axis_changed.connect(func(axis: Vector2) -> void: touch_axis_changed.emit(axis))
	touch_layer.add_child(pad)
	var actions := HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-464, -125)
	actions.add_theme_constant_override("separation", 8)
	touch_layer.add_child(actions)
	var attack := _button("HIT", Color("e7a36e"), 23)
	attack.pressed.connect(func() -> void: attack_requested.emit())
	actions.add_child(attack)
	var build := _button("BUILD", Color("b5d481"), 21)
	build.pressed.connect(func() -> void: build_requested.emit())
	actions.add_child(build)
	var dash := _button("DASH", Color("89c4d3"), 21)
	dash.pressed.connect(func() -> void: dash_requested.emit())
	actions.add_child(dash)
	var repair := _button("PATCH", Color("e8cd9b"), 20)
	repair.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	repair.position = Vector2(-156, -199)
	repair.pressed.connect(func() -> void: repair_requested.emit())
	touch_layer.add_child(repair)
	touch_layer.visible = false


func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
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
	menu_title.text = "HOME AGAIN" if won else "THE HEARTH FELL"
	menu_copy.text = summary
	menu_button.text = "MARCH AGAIN"
	menu_button.grab_focus.call_deferred()


func update_status(hearth_health: int, player_health: int, copper: int, stage: int) -> void:
	hearth_label.text = "%d / 200" % hearth_health
	player_label.text = "PIP  %d" % player_health
	scrap_label.text = "COPPER  %d" % copper
	wave_label.text = ["MEADOW · FIRST WAVE", "BRAMBLE · SECOND WAVE", "IRON MARSH · FINAL WAVE"][clampi(stage, 0, 2)]


func toast(text: String) -> void:
	toast_label.text = text
	toast_timer = 2.2
