class_name PalewheelHud
extends CanvasLayer

signal begin_pressed
signal pause_pressed

const INK: Color = Color("17142b")
const PAPER: Color = Color("fff0bc")
const ACCENT: Color = Color("eaa250")
const MUTED: Color = Color("51d7d0")
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
var guide_label: Label
var panel_button: Button
var regular_font: FontVariation
var heavy_font: FontVariation
var status_items: Array[Control] = []
var direction_panel: Panel
var pause_button: Button
var portrait: TextureRect


func _ready() -> void:
	layer = 1
	regular_font = _font(650)
	heavy_font = _font(850)
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var status: Panel = _panel(Rect2(38, 28, 795, 102), Color("211c37", 0.92))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label = _label(root, Vector2(66, 35), Vector2(730, 48), 34, PAPER, true)
	progress_label = _label(root, Vector2(67, 79), Vector2(720, 39), 25, ACCENT)
	direction_panel = _panel(Rect2(1460, 28, 298, 82), Color("211c37", 0.92))
	direction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gravity_label = _label(root, Vector2(1470, 36), Vector2(270, 61), 27, PAPER, true)
	gravity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_button = _button(root, Rect2(1781, 28, 96, 82), "II", Color("211c37"), PAPER)
	pause_button.tooltip_text = "Pause"
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	hint_back = _panel(Rect2(475, 145, 970, 63), Color("211c37", 0.94))
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label = _label(root, Vector2(495, 146), Vector2(930, 60), 30, PAPER, true)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_items.assign([status, title_label, progress_label, direction_panel, gravity_label, pause_button, hint_back, hint_label])
	_build_panel()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _layout() -> void:
	var width: float = root.size.x
	direction_panel.position.x = width - 460.0
	gravity_label.position.x = width - 450.0
	pause_button.position.x = width - 139.0
	hint_back.position.x = (width - hint_back.size.x) * 0.5
	hint_label.position.x = (width - hint_label.size.x) * 0.5
	portrait.position.x = width - 857.0


func _font(weight: int) -> FontVariation:
	var value: FontVariation = FontVariation.new()
	value.base_font = FONT
	value.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	value.variation_embolden = 0.0 if weight < 800 else 0.35
	return value


func _style(color: Color, border: Color = INK, width: int = 3) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(0)
	style.shadow_color = Color("090d13", 0.34)
	style.shadow_size = 0
	style.shadow_offset = Vector2(5, 5)
	return style


func _panel(rect: Rect2, color: Color) -> Panel:
	var value: Panel = Panel.new()
	value.position = rect.position
	value.size = rect.size
	value.add_theme_stylebox_override("panel", _style(color, ACCENT, 2))
	root.add_child(value)
	return value


func _label(parent: Control, pos: Vector2, extent: Vector2, size_px: int, color: Color, heavy: bool = false) -> Label:
	var value: Label = Label.new()
	value.position = pos
	value.size = extent
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_override("font", heavy_font if heavy else regular_font)
	value.add_theme_font_size_override("font_size", size_px)
	value.add_theme_color_override("font_color", color)
	parent.add_child(value)
	return value


func _button(parent: Control, rect: Rect2, caption: String, background: Color, foreground: Color) -> Button:
	var value: Button = Button.new()
	value.position = rect.position
	value.size = rect.size
	value.text = caption
	value.focus_mode = Control.FOCUS_ALL
	value.add_theme_font_override("font", heavy_font)
	value.add_theme_font_size_override("font_size", 37)
	value.add_theme_color_override("font_color", foreground)
	value.add_theme_color_override("font_hover_color", foreground)
	value.add_theme_color_override("font_pressed_color", foreground)
	value.add_theme_stylebox_override("normal", _style(background, ACCENT, 4))
	value.add_theme_stylebox_override("hover", _style(background.lightened(0.11), ACCENT, 5))
	value.add_theme_stylebox_override("pressed", _style(background.darkened(0.14), ACCENT, 5))
	value.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, foreground, 3))
	parent.add_child(value)
	return value


func _build_panel() -> void:
	panel = ColorRect.new()
	panel.color = Color("17142b", 0.90)
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var edition: Label = _label(panel, Vector2(132, 116), Vector2(900, 50), 28, ACCENT, true)
	edition.text = "1997  /  GRAVITY ENGINE"
	var rule: ColorRect = ColorRect.new()
	rule.position = Vector2(132, 188)
	rule.size = Vector2(155, 8)
	rule.color = ACCENT
	panel.add_child(rule)
	panel_title = _label(panel, Vector2(128, 223), Vector2(900, 146), 101, PAPER, true)
	panel_body = _label(panel, Vector2(139, 390), Vector2(805, 100), 37, PAPER)
	panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var guide_rule: ColorRect = ColorRect.new()
	guide_rule.position = Vector2(140, 534)
	guide_rule.size = Vector2(748, 3)
	guide_rule.color = MUTED
	panel.add_child(guide_rule)
	guide_label = _label(panel, Vector2(140, 562), Vector2(830, 245), 29, PAPER)
	guide_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	guide_label.text = "SLIDE LEFT / RIGHT    MOVE\nSWIPE UP    JUMP      SWIPE DOWN    CROUCH\nTAP    SHIFT GRAVITY" if DisplayServer.is_touchscreen_available() else "A / D  OR  LEFT / RIGHT    MOVE\nW / UP / SPACE    JUMP      S / DOWN    CROUCH\nSHIFT  OR  CLICK    SHIFT GRAVITY"
	panel_button = _button(panel, Rect2(139, 849, 500, 112), "START RUN", ACCENT, INK)
	panel_button.pressed.connect(func() -> void: begin_pressed.emit())
	portrait = TextureRect.new()
	portrait.texture = preload("res://assets/art/retro_idle.png")
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.position = Vector2(1063, 154)
	portrait.size = Vector2(770, 830)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait)


func show_panel(title: String, body: String, button: String) -> void:
	panel.visible = true
	for item: Control in status_items:
		item.visible = false
	panel_title.text = title
	panel_body.text = body
	guide_label.visible = title.begins_with("PALEWHEEL")
	panel_button.text = button
	panel_button.grab_focus()


func hide_panel() -> void:
	panel.visible = false
	for item: Control in status_items:
		item.visible = true


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
