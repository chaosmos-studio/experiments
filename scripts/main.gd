extends Control

const Rules = preload("res://scripts/puzzle.gd")
const INK := Color("283f3b")
const MUTED := Color("7c8478")
const PAPER := Color("f3f0e6")
const COLORS := [Color("d97b5c"), Color("559f92"), Color("d6ad50"), Color("8982b1"), Color("6994bb"), Color("c57894")]
const PLATE_COLORS := [Color("e5d5bb"), Color("bacdc2"), Color("d7c8bc"), Color("c7cfd8"), Color("d9d1b3")]
const BOARD := Vector2(74, 266)
const SAVE_PATH := "user://rivet.json"
const CAMPAIGN_VERSION := 3

var font: Font
var bold: FontVariation
var rules = Rules.new()
var levels: Array = []
var level_index := 0
var removed: int = 0
var tray: Array[int] = []
var history: Array = []
var completed: Dictionary = {}
var unaided: Dictionary = {}
var legacy_completion: Dictionary = {}
var campaign_updated := false
var undos_used := 0
var hints_used := 0
var returns_used := 0
var state_revision := 0
var hint_return_id := -1
var buttons: Array = []
var screen := "play"
var hover := Vector2(-100, -100)
var hint_index := -1
var keyboard_index := -1
var message := ""
var message_time := 0.0
var clock := 0.0
var sound_on := true
var reduced_motion := false
var animating := 0.0
var flights: Array = []
var bursts: Array = []
var fading: Dictionary = {}
var matched := 0
var peak := 0
var audio: AudioStreamPlayer
var sound_pick = preload("res://assets/pick.wav")
var sound_match = preload("res://assets/match.wav")
var sound_win = preload("res://assets/win.wav")
var last_web_state := ""

func _ready() -> void:
	font = ThemeDB.fallback_font
	bold = FontVariation.new()
	bold.base_font = font
	bold.variation_embolden = 0.7
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	if not parsed is Array or parsed.is_empty():
		push_error("No puzzle levels could be loaded.")
		return
	levels = parsed
	audio = AudioStreamPlayer.new()
	add_child(audio)
	_load_save()
	_load_level(level_index)
	if campaign_updated:
		_toast("New rules: match three neighbours. Tap tray to return.")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.rivetReady = true;")
	print("RIVET_READY levels=", levels.size())

func _layout_scale() -> float:
	return minf(size.x / 720.0, size.y / 1000.0)

func _origin() -> Vector2:
	return (size - Vector2(720, 1000) * _layout_scale()) * 0.5

func _process(delta: float) -> void:
	clock += delta
	animating = maxf(0.0, animating - delta)
	message_time = maxf(0.0, message_time - delta)
	for f in flights:
		f.t += delta
	flights = flights.filter(func(f): return f.t < 0.35)
	for b in bursts:
		b.t += delta
	bursts = bursts.filter(func(b): return b.t < 0.6)
	for p in fading.keys():
		fading[p] -= delta
		if fading[p] <= 0:
			fading.erase(p)
	_sync_web_state()
	queue_redraw()

func _sync_web_state() -> void:
	if not OS.has_feature("web"):
		return
	var state := JSON.stringify({"level": level_index + 1, "screen": screen,
		"tray": tray.size(), "sets": matched, "removed": str(removed),
		"campaign": CAMPAIGN_VERSION, "undos": undos_used, "hints": hints_used,
		"returns": returns_used, "order": ",".join(PackedStringArray(tray.map(func(i): return str(i)))),
		"hint_return": hint_return_id})
	if state == last_web_state:
		return
	last_web_state = state
	JavaScriptBridge.eval("(() => {const s=" + state + ";const e=document.getElementById('game-state');if(e){for(const k in s)e.dataset[k]=s[k];e.textContent='Study '+s.level+'. '+s.tray+' of 7 tray spaces used. '+s.sets+' sets collected. '+s.screen;}})();")

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not saved is Dictionary:
		return
	level_index = clampi(int(saved.get("level", 0)), 0, levels.size() - 1)
	if saved.get("completed", {}) is Dictionary:
		completed = saved.get("completed", {})
	if saved.get("unaided", {}) is Dictionary:
		unaided = saved.get("unaided", {})
	if saved.get("legacy_completion", {}) is Dictionary:
		legacy_completion = saved.get("legacy_completion", {})
	if int(saved.get("campaign_version", 1)) != CAMPAIGN_VERSION:
		legacy_completion[str(int(saved.get("campaign_version", 1)))] = completed.duplicate(true)
		completed.clear()
		unaided.clear()
		level_index = 0
		campaign_updated = true
	sound_on = bool(saved.get("sound", true))
	reduced_motion = bool(saved.get("reduced_motion", false))

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"level": level_index, "completed": completed,
			"campaign_version": CAMPAIGN_VERSION, "unaided": unaided,
			"legacy_completion": legacy_completion,
			"sound": sound_on, "reduced_motion": reduced_motion}))

func _load_level(index: int) -> void:
	state_revision += 1
	level_index = clampi(index, 0, levels.size() - 1)
	rules.configure(levels[level_index])
	removed = 0
	tray.clear()
	history.clear()
	flights.clear()
	bursts.clear()
	fading.clear()
	hint_index = -1
	keyboard_index = -1
	matched = 0
	peak = 0
	undos_used = 0
	hints_used = 0
	returns_used = 0
	hint_return_id = -1
	animating = 0
	screen = "play"
	_save()

func _play(stream: AudioStream) -> void:
	if sound_on:
		audio.stream = stream
		audio.play()

func _remember() -> void:
	history.append({"mask": removed, "tray": tray.duplicate(), "matched": matched, "peak": peak})

func _take(index: int) -> void:
	# Visual animations never block a legal action.
	if screen != "play":
		return
	var next: Dictionary = rules.collect(index, removed, tray)
	if next.is_empty():
		return
	_remember()
	var line: Array[int] = tray.duplicate()
	line.append(index)
	flights.append({"from": BOARD + Vector2(rules.screws[index].x, rules.screws[index].y),
		"to": Vector2(108 + tray.size() * 84, 818), "color": int(rules.screws[index].color), "t": 0.0})
	_apply_move(next, line)

func _return_screw(index: int) -> void:
	if screen not in ["play", "full"]:
		return
	var next: Dictionary = rules.put_back(index, removed, tray)
	if next.is_empty():
		return
	_remember()
	var slot := tray.find(index)
	var line: Array[int] = tray.duplicate()
	line.erase(index)
	flights.append({"from": Vector2(108 + slot * 84, 818),
		"to": BOARD + Vector2(rules.screws[index].x, rules.screws[index].y),
		"color": int(rules.screws[index].color), "t": 0.0})
	returns_used += 1
	_apply_move(next, line)
	_toast("Returned to panel %d." % (int(rules.screws[index].plate) + 1))

func _apply_move(next: Dictionary, visual_line: Array[int]) -> void:
	state_revision += 1
	var before := removed
	removed = int(next.mask)
	tray.assign(next.tray)
	matched += int(next.sets)
	hint_index = -1
	hint_return_id = -1
	keyboard_index = -1
	for index in next.cleared:
		bursts.append({"pos": Vector2(108 + visual_line.find(index) * 84, 818),
			"color": int(rules.screws[index].color), "t": -0.18})
	_play(sound_match if int(next.sets) > 0 else sound_pick)
	peak = maxi(peak, tray.size())
	for panel in rules.plates.size():
		if rules.plate_active(panel, before) and not rules.plate_active(panel, removed):
			fading[panel] = 0.32
		elif rules.plate_active(panel, removed):
			fading.erase(panel)
	animating = 0.05 if reduced_motion else 0.3
	screen = _play_screen()
	if rules.is_won(removed, tray):
		completed[str(level_index)] = true
		if undos_used == 0 and hints_used == 0:
			unaided[str(level_index)] = true
		_save()
		_finish_after_animation()
	elif screen == "full":
		_toast("Tray full. Tap a tray screw to put it back.")

func _play_screen() -> String:
	return "full" if tray.size() >= Rules.CAPACITY else "play"

func _finish_after_animation() -> void:
	var expected_revision := state_revision
	await get_tree().create_timer(0.42).timeout
	if state_revision == expected_revision and rules.is_won(removed, tray):
		screen = "won"
		_play(sound_win)

func _undo() -> void:
	if history.is_empty():
		_toast("No moves to undo.")
		return
	state_revision += 1
	var state: Dictionary = history.pop_back()
	undos_used += 1
	removed = state.mask
	tray.assign(state.tray)
	matched = state.matched
	peak = state.peak
	flights.clear()
	bursts.clear()
	fading.clear()
	hint_index = -1
	hint_return_id = -1
	animating = 0
	screen = _play_screen()

func _hint() -> void:
	if screen not in ["play", "full"]:
		return
	var route: Array[int] = rules.solve(removed, tray, 30000)
	if not route.is_empty() and route[0] != -1:
		hints_used += 1
		hint_index = route[0] if route[0] >= 0 else -1
		hint_return_id = -route[0]-2 if route[0] < -1 else -1
		_toast("Return the highlighted tray screw." if hint_return_id >= 0 else "Take the highlighted screw.")
	else:
		_toast("No quick route found. Try returning a screw or undoing.")

func _toast(text: String) -> void:
	message = text
	message_time = 3.8

func _action(action: String) -> void:
	match action:
		"levels": screen = "levels"
		"help": screen = "help"
		"inspect": screen = "inspect"
		"close": screen = _play_screen()
		"sound":
			sound_on = not sound_on
			_save()
		"motion":
			reduced_motion = not reduced_motion
			_save()
		"undo": _undo()
		"hint": _hint()
		"restart": _load_level(level_index)
		"next":
			if level_index + 1 < levels.size():
				_load_level(level_index + 1)
			else:
				screen = "levels"
		_:
			if action.begins_with("level:"):
				_load_level(int(action.get_slice(":", 1)))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = (event.position - _origin()) / _layout_scale()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = (event.position - _origin()) / _layout_scale()
		for b in buttons:
			if b.rect.has_point(point):
				_action(b.action)
				accept_event()
				return
		if screen in ["play", "full"]:
			for slot in tray.size():
				if point.distance_to(Vector2(108 + slot * 84, 818)) < 35:
					_return_screw(tray[slot])
					accept_event()
					return
		if screen != "play":
			return
		# Hit test the top visible screw, with a larger touch target than its head.
		for i in range(rules.screws.size() - 1, -1, -1):
			var s: Dictionary = rules.screws[i]
			if point.distance_to(BOARD + Vector2(s.x, s.y)) < 35 and rules.exposed(i, removed):
				_take(i)
				accept_event()
				return

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_7 and screen in ["play", "full"]:
		var slot: int = event.keycode - KEY_1
		if slot < tray.size():
			_return_screw(tray[slot])
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_ESCAPE:
			if screen in ["help", "levels", "inspect"]:
				screen = _play_screen()
		KEY_U, KEY_Z:
			if screen in ["play", "full"]:
				_undo()
		KEY_R: _load_level(level_index)
		KEY_H: _hint()
		KEY_I:
			if screen in ["play", "full", "inspect"]:
				screen = _play_screen() if screen == "inspect" else "inspect"
		KEY_M: _action("sound")
		KEY_ENTER, KEY_SPACE:
			if screen == "won":
				_action("next")
			elif keyboard_index >= 0:
				_take(keyboard_index)
		KEY_TAB, KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP:
			if screen == "play":
				var options: Array[int] = []
				for i in rules.screws.size():
					if rules.exposed(i, removed):
						options.append(i)
				if not options.is_empty():
					var direction := -1 if event.keycode in [KEY_LEFT, KEY_UP] or event.shift_pressed else 1
					keyboard_index = options[posmod(options.find(keyboard_index) + direction, options.size())]
	get_viewport().set_input_as_handled()

func _box(rect: Rect2, color: Color, radius: int = 16, border: Color = Color.TRANSPARENT, width: int = 1) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.set_border_width_all(width)
	draw_style_box(style, rect)

func _text(text: String, pos: Vector2, size_px: int, color: Color = INK, strong: bool = false) -> void:
	draw_string(bold if strong else font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func _center(text: String, x: float, y: float, size_px: int, color: Color = INK, strong: bool = false) -> void:
	var f: Font = bold if strong else font
	_text(text, Vector2(x - f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x / 2, y), size_px, color, strong)

func _button(rect: Rect2, label: String, action: String, filled: bool = false, small: bool = false) -> void:
	var is_hover := rect.has_point(hover)
	var bg := INK if filled else Color("e9e5da")
	if is_hover:
		bg = bg.lightened(0.07) if filled else Color("deded0")
	_box(rect, bg, 14)
	_center(label, rect.get_center().x, rect.get_center().y + (6 if small else 8), 18 if small else 23, PAPER if filled else INK, filled)
	buttons.append({"rect": rect, "action": action})

func _screw(pos: Vector2, color_id: int, radius: float = 27.0, alpha: float = 1.0, angle: float = 0.0) -> void:
	var c: Color = COLORS[color_id]
	draw_circle(pos + Vector2(0, 4), radius + 1, Color(0.13, 0.21, 0.18, 0.2 * alpha), true, -1, true)
	draw_circle(pos, radius, Color(c.darkened(0.19), alpha), true, -1, true)
	draw_circle(pos + Vector2(0, -2), radius - 3, Color(c, alpha), true, -1, true)
	draw_arc(pos + Vector2(0, -2), radius - 5, PI * 1.1, PI * 1.8, 18, Color(1, 1, 0.93, 0.28 * alpha), 2.0, true)
	# Six distinct stamped symbols make colour optional.
	var dark := Color(c.darkened(0.53), alpha)
	var r := radius * 0.36
	var center := pos + Vector2(0, -2)
	match color_id:
		0:
			draw_line(center + Vector2(-r, -r).rotated(angle), center + Vector2(r, r).rotated(angle), dark, 4, true)
			draw_line(center + Vector2(r, -r).rotated(angle), center + Vector2(-r, r).rotated(angle), dark, 4, true)
		1: draw_arc(center, r, 0, TAU, 24, dark, 4, true)
		2:
			var points := PackedVector2Array([center + Vector2(0, -r-2), center + Vector2(r+1, r), center + Vector2(-r-1, r), center + Vector2(0, -r-2)])
			draw_polyline(points, dark, 3.5, true)
		3:
			draw_line(center + Vector2(-r, 0), center + Vector2(r, 0), dark, 4, true)
			draw_line(center + Vector2(0, -r), center + Vector2(0, r), dark, 4, true)
		4:
			draw_rect(Rect2(center - Vector2(r, r), Vector2(r*2, r*2)), dark, false, 3.5)
		5:
			draw_circle(center + Vector2(-r*0.65, 0), 3.3, dark, true, -1, true)
			draw_circle(center + Vector2(r*0.65, 0), 3.3, dark, true, -1, true)

func _draw() -> void:
	if levels.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	draw_set_transform(_origin(), 0, Vector2.ONE * _layout_scale())
	buttons.clear()
	_text("R I V E T", Vector2(48, 76), 36, INK, true)
	_text("A SMALL SORTING WORKSHOP", Vector2(50, 104), 12, MUTED)
	_button(Rect2(307, 40, 112, 49), "Inspect", "inspect", false, true)
	_button(Rect2(431, 40, 104, 49), "Levels", "levels", false, true)
	_button(Rect2(547, 40, 54, 49), "On" if sound_on else "Off", "sound", false, true)
	_button(Rect2(613, 40, 54, 49), "?", "help")
	draw_line(Vector2(48, 129), Vector2(672, 129), Color("d9dccf"), 1)
	_text("STUDY %02d / %02d   ·   %s" % [level_index+1, levels.size(), str(levels[level_index].get("chapter", "Plan")).to_upper()], Vector2(50, 170), 14, MUTED, true)
	_text(levels[level_index].name, Vector2(48, 214), 34, INK, true)
	_text("%02d" % matched, Vector2(585, 199), 34, INK, true)
	_text("SETS", Vector2(590, 218), 11, MUTED)
	_draw_board()
	_draw_tray()
	_button(Rect2(64, 888, 184, 57), "Undo", "undo")
	_button(Rect2(268, 888, 184, 57), "Hint", "hint", true)
	_button(Rect2(472, 888, 184, 57), "Restart", "restart")
	var guidance := "Tap a tray screw to return it. Keyboard: 1–7."
	if tray.size() >= 7:
		guidance = "Tray full. Return a screw to make space."
	elif tray.size() >= 5:
		guidance = "Keep matching colours next to each other."
	_center(guidance, 360, 978, 15, Color("b1624b") if tray.size() >= 5 else MUTED)
	if message_time > 0 and screen in ["play", "full"]:
		_box(Rect2(60, 698, 600, 40), INK, 12)
		_center(message, 360, 724, 17, PAPER)
	if screen not in ["play", "full"]:
		buttons.clear()
		draw_rect(Rect2(0, 0, 720, 1000), Color(0.12, 0.21, 0.18, 0.62))
		match screen:
			"help": _draw_help()
			"inspect": _draw_inspect()
			"levels": _draw_levels()
			"won": _draw_result()

func _draw_board() -> void:
	_box(Rect2(48, 241, 624, 492), Color("e9e6da"), 22, Color("dfdfd2"))
	for x in range(64, 661, 22):
		for y in range(255, 720, 22):
			draw_circle(Vector2(x, y), 0.8, Color("d5d6c8"))
	for p in rules.plates.size():
		if not rules.plate_active(p, removed) and not fading.has(p):
			continue
		var alpha: float = 1.0 if rules.plate_active(p, removed) else float(fading.get(p, 0)) / 0.32
		if reduced_motion and alpha < 1:
			continue
		var data: Dictionary = rules.plates[p]
		var r: Array = data.rect
		var rect := Rect2(BOARD + Vector2(r[0], r[1]), Vector2(r[2], r[3]))
		var c: Color = PLATE_COLORS[int(data.style)]
		_box(Rect2(rect.position + Vector2(0, 6), rect.size), Color(0.17, 0.23, 0.17, 0.16 * alpha), 19)
		_box(rect, Color(c, alpha), 18, Color(c.darkened(0.12), alpha), 1)
		# A fine inset edge gives panels a machined, tactile finish.
		_box(rect.grow(-5), Color.TRANSPARENT, 14, Color(1, 1, 0.9, 0.24*alpha), 1)
		_text(str(p+1), rect.position + Vector2(9, 16), 11, Color(INK, alpha * 0.65), true)
		for i in rules.screws.size():
			var s: Dictionary = rules.screws[i]
			if int(s.plate) != p:
				continue
			var pos := BOARD + Vector2(s.x, s.y)
			if removed & (1 << i):
				draw_circle(pos, 10, Color(c.darkened(0.18), alpha), true, -1, true)
				draw_circle(pos + Vector2(0, 1), 6, Color(c.darkened(0.38), alpha), true, -1, true)
			else:
				_screw(pos, int(s.color), 27.0, alpha)
	# Draw focus above every panel, but only for exposed targets.
	for i in rules.screws.size():
		if not rules.exposed(i, removed):
			continue
		var s: Dictionary = rules.screws[i]
		var pos := BOARD + Vector2(s.x, s.y)
		if i == hint_index or i == keyboard_index or (screen == "play" and hover.distance_to(pos) < 30):
			var pulse := 1.0 if reduced_motion else 1.0 + sin(clock * 4) * 0.06
			draw_arc(pos, 33.0 * pulse, 0, TAU, 48, INK, 2.5, true)
	for f in flights:
		if reduced_motion:
			continue
		var t := clampf(float(f.t) / 0.3, 0.0, 1.0)
		var pos: Vector2 = f.from.lerp(f.to, 1 - pow(1-t, 3))
		pos.y -= sin(t * PI) * 42
		_screw(pos, int(f.color), 26, 1.0-t*0.25, t*PI)

func _draw_tray() -> void:
	_text("TRAY FULL — TAP A SCREW TO RETURN" if tray.size() >= 7 else "MATCH THREE IN A ROW. ORDER MATTERS.", Vector2(65, 768), 13, Color("b1624b") if tray.size() >= 6 else MUTED, true)
	_text("%d / 7" % tray.size(), Vector2(607, 768), 14, Color("b1624b") if tray.size() >= 5 else MUTED)
	_box(Rect2(64, 785, 592, 70), Color("dfdfd1"), 18)
	for k in 7:
		var pos := Vector2(108 + k * 84, 818)
		draw_circle(pos, 29, Color("d2d5c7"), true, -1, true)
		draw_arc(pos, 28, 0, TAU, 36, Color("c6cabc"), 1, true)
		_center(str(k+1), pos.x, 874, 13, MUTED)
		if k < 6:
			draw_line(pos + Vector2(34, 0), pos + Vector2(50, 0), MUTED, 1.0, true)
			draw_line(pos + Vector2(46, -3), pos + Vector2(50, 0), MUTED, 1.0, true)
		if k < tray.size():
			_screw(pos, int(rules.screws[tray[k]].color), 25)
			if tray[k] == hint_return_id or (screen in ["play", "full"] and hover.distance_to(pos) < 30):
				draw_arc(pos, 32, 0, TAU, 40, INK, 2.5, true)
		else:
			draw_circle(pos, 2, Color("b4bcac"), true, -1, true)
	for b in bursts:
		if reduced_motion or b.t < 0:
			continue
		var t: float = b.t / 0.6
		for n in 8:
			var pos: Vector2 = b.pos + Vector2.from_angle(n * TAU / 8.0) * (10 + t*55)
			draw_circle(pos, 4*(1-t), Color(COLORS[int(b.color)], 1-t), true, -1, true)

func _draw_help() -> void:
	_box(Rect2(55, 150, 610, 707), PAPER, 26)
	_text("A little order.", Vector2(90, 218), 36, INK, true)
	_text("Clear the panels and empty the tray.", Vector2(91, 258), 21, MUTED)
	var instructions := [
		["01", "Keep your order", "Each screw joins the right end of the tray.", "Colours are never rearranged for you."],
		["02", "Match three in a row", "Three matching neighbours disappear.", "Separated matches stay in the tray."],
		["03", "Put a screw back", "Tap a tray screw to return it to its panel.", "Closing the gap can create a triple."]]
	for i in instructions.size():
		var y := 317 + i * 115
		_text(instructions[i][0], Vector2(92, y), 19, Color("b1624b"), true)
		_text(instructions[i][1], Vector2(139, y), 23, INK, true)
		_text(instructions[i][2], Vector2(139, y + 30), 17, MUTED)
		_text(instructions[i][3], Vector2(139, y + 54), 17, MUTED)
	_center("Arrows choose · Enter takes · 1–7 return", 360, 666, 17, MUTED)
	_center("U undo · H hint · I inspect · R restart · M sound", 360, 695, 17, MUTED)
	_button(Rect2(91, 725, 270, 52), "Motion: low" if reduced_motion else "Motion: full", "motion", false, true)
	_button(Rect2(379, 725, 250, 52), "Let’s begin", "close", true)
	_center("Returning screws is part of the puzzle. No penalty.", 360, 823, 16, MUTED)

func _draw_inspect() -> void:
	_box(Rect2(55, 123, 610, 777), PAPER, 26)
	_text("Look underneath.", Vector2(90, 180), 32, INK, true)
	_text("All remaining colours, from top panel to bottom.", Vector2(91, 217), 17, MUTED)
	_text("Panel numbers are printed on the board. No hint used.", Vector2(91, 243), 16, MUTED)
	var row := 0
	for p in range(rules.plates.size()-1, -1, -1):
		if not rules.plate_active(p, removed):
			continue
		var y := 286 + row * 42
		_text("Panel %02d" % (p+1), Vector2(94, y+5), 18, INK, true)
		var column := 0
		var exposed_count := 0
		for i in rules.screws.size():
			if int(rules.screws[i].plate) != p:
				continue
			var pos := Vector2(275 + column * 56, y)
			if not removed & (1 << i):
				_screw(pos, int(rules.screws[i].color), 16)
				if rules.exposed(i, removed):
					exposed_count += 1
			else:
				draw_circle(pos, 5, Color("c6cabc"), true, -1, true)
			column += 1
		_text("%d exposed" % exposed_count, Vector2(467, y+5), 16, MUTED)
		row += 1
	_button(Rect2(91, 820, 538, 55), "Back to the puzzle", "close", true)

func _draw_levels() -> void:
	_box(Rect2(55, 155, 610, 693), PAPER, 26)
	_text("The collection", Vector2(90, 219), 34, INK, true)
	_text("%d of %d studies complete" % [completed.size(), levels.size()], Vector2(91, 255), 19, MUTED)
	_text("1–3 Learn   ·   4–12 Plan   ·   13–24 Think ahead   ·   25–36 Master", Vector2(91, 279), 13, MUTED)
	for i in levels.size():
		var rect := Rect2(91 + (i % 6) * 90, 291 + (i / 6) * 73, 78, 60)
		_button(rect, "%02d" % (i+1), "level:%d" % i, i == level_index)
		if completed.has(str(i)):
			draw_circle(rect.position + Vector2(64, 12), 4, Color("6a9d89"), unaided.has(str(i)), 1.5, true)
	_button(Rect2(91, 751, 538, 56), "Back to the workbench", "close", true)

func _draw_result() -> void:
	_box(Rect2(74, 303, 572, 381), PAPER, 26)
	_center("STUDY %02d" % (level_index+1), 360, 353, 15, MUTED, true)
	_center("All in order.", 360, 413, 38, INK, true)
	var result_note := "Unaided solve." if undos_used == 0 and hints_used == 0 else "%d undos  /  %d hints" % [undos_used, hints_used]
	_center(result_note, 360, 459, 20, MUTED)
	_center("%d sets  /  %d returns  /  peak tray %d" % [matched, returns_used, peak], 360, 508, 17, MUTED)
	_button(Rect2(112, 544, 496, 61), "Next study" if level_index < levels.size()-1 else "Back to collection", "next", true)
	_button(Rect2(218, 616, 284, 42), "Play this study again", "restart", false, true)
