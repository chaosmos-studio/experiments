extends Node2D

const Puzzle = preload("res://scripts/puzzle.gd")
const FONT_FILE = preload("res://assets/fonts/Manrope.ttf")
const SAVE_PATH: String = "user://hinge-grove-v1.cfg"
const PITCH: float = 128.0
const SWING_SECONDS: float = 0.34
const BG: Color = Color("f5f3eb")
const INK: Color = Color("273d35")
const MUTED: Color = Color("667367")
const COLORS: Array[Color] = [Color("39775e"), Color("b65a3c"), Color("5175a1")]
const PALE: Array[Color] = [Color("dde8d7"), Color("f1dfd0"), Color("dce6f1")]

var font: FontVariation
var heading: FontVariation
var levels: Array = []
var level: Dictionary = {}
var state: Array = []
var history: Array = []
var current: int = 0
var moves: int = 0
var completed: Dictionary = {}
var selected_piece: int = -1
var selected_pivot: int = -1
var choices: Array = []
var hint_move: Array = []
var message: String = ""
var message_time: float = 0.0
var screen: String = "play"
var page: int = 0
var sound_on: bool = true
var music_on: bool = true
var reduced_motion: bool = false
var music: AudioStreamPlayer
var sounds: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var audio_started: bool = false
var elapsed: float = 0.0
var animation: Dictionary = {}
var anim_time: float = 0.0
var bloom_time: float = 0.0
var solved: bool = false
var buttons: Array = []
var touch_id: int = -1
var gesture_start: Vector2 = Vector2.ZERO
var gesture_end: Vector2 = Vector2.ZERO
var gesture_active: bool = false
var cursor: int = 0
var keyboard_visible: bool = false
var last_debug: String = ""

func _ready() -> void:
	font = FontVariation.new()
	font.base_font = FONT_FILE
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 500.0}
	heading = FontVariation.new()
	heading.base_font = FONT_FILE
	heading.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 650.0}
	levels = Puzzle.load_levels()
	_restore()
	_setup_audio()
	_load_level(current)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.hingeReady=true;")

func _setup_audio() -> void:
	for name: String in ["turn", "root", "bloom", "undo"]:
		var path: String = "res://assets/audio/" + name + ".wav"
		if ResourceLoader.exists(path):
			sounds[name] = load(path)
	for i: int in range(5):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	music = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/audio/grove.ogg"):
		music.stream = load("res://assets/audio/grove.ogg")
	music.volume_db = -21.0
	add_child(music)
	music.finished.connect(func() -> void:
		if music_on:
			music.play())

func _unlock_audio() -> void:
	if not audio_started:
		audio_started = true
		if music_on and music.stream != null:
			music.play()

func _sound(name: String) -> void:
	if not sound_on or not sounds.has(name):
		return
	for player: AudioStreamPlayer in players:
		if not player.playing:
			player.stream = sounds[name]
			player.volume_db = -9.0
			player.play()
			break

func _restore() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		current = clampi(int(config.get_value("progress", "level", 0)), 0, 29)
		var saved: Variant = config.get_value("progress", "completed", {})
		if saved is Dictionary:
			completed = saved
		sound_on = bool(config.get_value("settings", "sound", true))
		music_on = bool(config.get_value("settings", "music", true))
		reduced_motion = bool(config.get_value("settings", "motion", false))

func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "level", current)
	config.set_value("progress", "completed", completed)
	config.set_value("settings", "sound", sound_on)
	config.set_value("settings", "music", music_on)
	config.set_value("settings", "motion", reduced_motion)
	config.save(SAVE_PATH)

func _load_level(index: int) -> void:
	current = clampi(index, 0, levels.size() - 1)
	level = levels[current]
	state = Puzzle.initial(level)
	moves = 0
	history.clear()
	_clear_selection()
	animation.clear()
	solved = false
	bloom_time = 0.0
	message_time = 0.0
	screen = "play"
	_save()
	_publish()
	queue_redraw()

func _clear_selection() -> void:
	selected_piece = -1
	selected_pivot = -1
	choices.clear()
	hint_move.clear()

func _process(delta: float) -> void:
	elapsed += delta
	message_time = maxf(0.0, message_time - delta)
	if not animation.is_empty():
		anim_time += delta
		if anim_time >= (0.06 if reduced_motion else SWING_SECONDS):
			animation.clear()
			_finish_move()
	if solved:
		bloom_time += delta
	_publish()
	queue_redraw()

func _origin() -> Vector2:
	var room: Vector2 = get_viewport_rect().size
	return Vector2(room.x * 0.5 - PITCH * 1.5, room.y * 0.49 - PITCH * 1.5)

func _cell(cell: int) -> Vector2:
	var xy: Vector2i = Puzzle.point(cell, int(level.size))
	return _origin() + Vector2(xy) * PITCH

func _round_box(rect: Rect2, color: Color, radius: int = 20, outline: Color = Color.TRANSPARENT, width: int = 0) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.border_color = outline
	box.set_border_width_all(width)
	draw_style_box(box, rect)

func _text(text: String, at: Vector2, size: int, color: Color = INK, bold: bool = false, centered: bool = false) -> void:
	var f: Font = heading if bold else font
	var p: Vector2 = at
	if centered:
		p.x -= f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _button(id: String, label: String, rect: Rect2, primary: bool = false) -> void:
	buttons.append({"id": id, "rect": rect})
	_round_box(rect, INK if primary else Color("ebece2"), 18)
	_text(label, rect.get_center() + Vector2(0, 8), 24, BG if primary else INK, primary, true)

func _draw() -> void:
	if level.is_empty():
		return
	buttons.clear()
	var room: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, room), BG)
	var mid: float = room.x * 0.5
	_text("Hinge Grove", Vector2(mid, 106), 42, INK, true, true)
	_text("A little room to grow", Vector2(mid, 146), 23, MUTED, false, true)
	buttons.append({"id": "settings", "rect": Rect2(room.x - 94, 68, 68, 68)})
	for dx: int in [-9, 0, 9]:
		draw_circle(Vector2(room.x - 60 + dx, 100), 2.7, INK, true, -1.0, true)
	if screen == "levels":
		_draw_gallery(room)
		return
	var chapter: String = "First turns" if current < 6 else ("Make room" if current < 18 else "Shared ground")
	_text(chapter.to_upper(), Vector2(mid, 217), 18, MUTED, false, true)
	_text("Garden %02d" % (current + 1), Vector2(mid, 265), 34, INK, true, true)
	_draw_board()
	var caption_y: float = _origin().y + 3.0 * PITCH + 114.0
	var caption: String = "Tap a seed, then a marked spot to swing."
	if selected_piece >= 0:
		caption = "This seed holds. Choose where its partner lands."
	if message_time > 0:
		caption = message
	if solved:
		caption = "Rooted, together."
	_text(caption, Vector2(mid, caption_y), 21, INK, false, true)
	_text("%d turns  /  best route %d" % [moves, int(level.par)], Vector2(mid, caption_y + 39), 21, MUTED, false, true)
	if current < 2 and not solved:
		_text("Matching soil holds a seed in place.", Vector2(mid, caption_y + 77), 20, MUTED, false, true)
	var row_y: float = room.y - 147
	for i: int in range(4):
		var x: float = mid - 234 + i * 156
		var id: String = ["undo", "hint", "reset", "levels"][i]
		_draw_action(id, Vector2(x, row_y))
	if solved and bloom_time > 0.4:
		_draw_win(room)
	if screen == "settings" or screen == "help" or screen == "ending":
		_draw_sheet(room)

func _draw_board() -> void:
	var origin: Vector2 = _origin()
	var board_rect: Rect2 = Rect2(origin - Vector2(79, 79), Vector2(PITCH * 3 + 158, PITCH * 3 + 158))
	_round_box(Rect2(board_rect.position + Vector2(0, 9), board_rect.size), Color("e2e4d7"), 42)
	_round_box(board_rect, Color("eaf0e3"), 42)
	for cell: int in range(int(level.size) * int(level.size)):
		var p: Vector2 = _cell(cell)
		if cell in level.walls:
			_draw_rock(p)
		else:
			draw_circle(p, 3.0, Color("bdcdb6"), true, -1.0, true)
	for i: int in range(level.goals.size()):
		for cell_value: Variant in level.goals[i]:
			var p: Vector2 = _cell(int(cell_value))
			draw_circle(p, 36.0, PALE[i], true, -1.0, true)
			draw_arc(p, 36.0, 0, TAU, 48, COLORS[i].lightened(0.15), 2.0, true)
			_mark(p, i, COLORS[i].darkened(0.12), 10.0)
	for choice: Dictionary in choices:
		var p: Vector2 = _cell(int(choice.pivot))
		var a: float = (_cell(int(choice.from)) - p).angle()
		var end: float = a + PI * 0.5 * int(choice.turn)
		var path: PackedVector2Array = []
		for step: int in range(19):
			path.append(p + Vector2.from_angle(lerpf(a, end, step / 18.0)) * PITCH)
		draw_polyline(path, COLORS[int(choice.piece)].lightened(0.2), 2.5, true)
		var target: Vector2 = _cell(int(choice.to))
		draw_circle(target, 32.0, Color("f8faf4"), true, -1.0, true)
		draw_arc(target, 32.0, 0, TAU, 48, COLORS[int(choice.piece)], 2.0, true)
		draw_circle(target, 6.0, COLORS[int(choice.piece)], true, -1.0, true)
	for i: int in range(state.size()):
		var a: Vector2 = _cell(int(state[i][0]))
		var b: Vector2 = _cell(int(state[i][1]))
		if not animation.is_empty() and int(animation.piece) == i:
			var pivot: Vector2 = _cell(int(animation.pivot))
			var start: Vector2 = _cell(int(animation.from))
			var amount: float = clampf(anim_time / (0.06 if reduced_motion else SWING_SECONDS), 0, 1)
			var ease: float = amount * amount * (3.0 - 2.0 * amount)
			var angle: float = (start - pivot).angle() + PI * 0.5 * int(animation.turn) * ease
			a = pivot
			b = pivot + Vector2.from_angle(angle) * PITCH
		var rooted: bool = state[i] == level.goals[i] and (animation.is_empty() or int(animation.piece) != i)
		_draw_stem(a, b, COLORS[i], rooted)
		for end: int in range(2):
			var p: Vector2 = a if end == 0 else b
			var cell: int = int(state[i][end])
			var locked: bool = cell in level.goals[i]
			if not animation.is_empty() and int(animation.piece) == i:
				locked = false
			_draw_seed(p, i, locked, rooted)
		if selected_piece == i:
			var pin: Vector2 = _cell(selected_pivot)
			draw_arc(pin, 43.0, 0, TAU, 64, INK, 2.0, true)
	if keyboard_visible:
		_round_box(Rect2(_cell(cursor) - Vector2(49, 49), Vector2(98, 98)), Color.TRANSPARENT, 16, INK, 2)

func _draw_rock(p: Vector2) -> void:
	var points: PackedVector2Array = [p + Vector2(-38, 8), p + Vector2(-25, -26), p + Vector2(7, -35), p + Vector2(36, -9), p + Vector2(34, 25), p + Vector2(-10, 33)]
	draw_colored_polygon(points, Color("b5beb0"))
	points.append(points[0])
	draw_polyline(points, Color("879783"), 2.0, true)
	draw_line(p + Vector2(-16, -13), p + Vector2(8, -23), Color("d7ded0"), 3.0, true)

func _draw_stem(a: Vector2, b: Vector2, color: Color, rooted: bool) -> void:
	draw_line(a + Vector2(0, 5), b + Vector2(0, 5), Color(0.22, 0.32, 0.22, 0.1), 17.0, true)
	draw_line(a, b, color.lightened(0.23), 11.0, true)
	var mid: Vector2 = a.lerp(b, 0.5)
	var d: Vector2 = (b - a).normalized()
	var normal: Vector2 = Vector2(-d.y, d.x)
	var sway: float = 0.0 if reduced_motion else sin(elapsed * 1.5 + mid.x) * 1.8
	var leaf: PackedVector2Array = [mid - d * 9, mid + normal * (21 + sway) - d * 6, mid + normal * 28 + d * 14, mid + d * 10]
	draw_colored_polygon(leaf, color.lightened(0.15 if rooted else 0.32))
	leaf.append(leaf[0])
	draw_polyline(leaf, color.lightened(0.15), 1.5, true)

func _draw_seed(p: Vector2, kind: int, locked: bool, flower: bool) -> void:
	var color: Color = COLORS[kind]
	if flower:
		for petal: int in range(5 + kind):
			var angle: float = TAU * petal / (5 + kind) - PI * 0.5
			var offset: Vector2 = Vector2.from_angle(angle) * 24.0
			draw_circle(p + offset + Vector2(0, 4), 20.0, Color(0.18, 0.3, 0.2, 0.09), true, -1.0, true)
			draw_circle(p + offset, 20.0, color.lightened(0.3), true, -1.0, true)
		draw_circle(p, 22.0, color, true, -1.0, true)
		_mark(p, kind, Color("fff7dd"), 9.0)
		return
	draw_circle(p + Vector2(0, 6), 32.0, Color(0.18, 0.3, 0.2, 0.14), true, -1.0, true)
	draw_circle(p, 32.0, color, true, -1.0, true)
	draw_arc(p + Vector2(-1, -1), 25.0, PI * 1.07, PI * 1.64, 24, color.lightened(0.32), 3.0, true)
	_mark(p, kind, Color("fff9e9"), 11.0)
	if locked:
		for root: int in range(3):
			var angle: float = PI * 0.25 + root * PI * 0.25
			draw_line(p + Vector2.from_angle(angle) * 33, p + Vector2.from_angle(angle) * 45, color, 2.5, true)
		draw_arc(p, 38, 0, TAU, 40, color, 2.0, true)

func _mark(p: Vector2, kind: int, color: Color, radius: float) -> void:
	if kind == 0:
		draw_circle(p, radius * 0.58, color, true, -1.0, true)
	elif kind == 1:
		var poly: PackedVector2Array = [p + Vector2(0, -radius), p + Vector2(radius, 0), p + Vector2(0, radius), p + Vector2(-radius, 0), p + Vector2(0, -radius)]
		draw_polyline(poly, color, 3.0, true)
	else:
		draw_line(p - Vector2(radius, 4), p + Vector2(radius, -4), color, 3, true)
		draw_line(p - Vector2(radius, -4), p + Vector2(radius, 4), color, 3, true)

func _draw_action(id: String, p: Vector2) -> void:
	buttons.append({"id": id, "rect": Rect2(p - Vector2(60, 39), Vector2(120, 100))})
	if id == "undo":
		draw_arc(p + Vector2(2, 0), 17, -PI * 0.85, PI * 0.7, 30, INK, 2.6, true)
		draw_polyline(PackedVector2Array([p + Vector2(-16, -19), p + Vector2(-16, -4), p + Vector2(-1, -4)]), INK, 2.6, true)
	elif id == "hint":
		draw_arc(p + Vector2(0, -4), 14, PI * 0.15, PI * 0.85 + TAU * 0.65, 40, INK, 2.5, true)
		draw_line(p + Vector2(-8, 15), p + Vector2(8, 15), INK, 2.5, true)
		draw_line(p + Vector2(-5, 21), p + Vector2(5, 21), INK, 2.5, true)
	elif id == "reset":
		draw_arc(p, 18, -PI * 0.3, PI * 1.4, 40, INK, 2.5, true)
		draw_polyline(PackedVector2Array([p + Vector2(5, -21), p + Vector2(19, -15), p + Vector2(18, -1)]), INK, 2.5, true)
	else:
		for x: int in range(2):
			for y: int in range(2):
				_round_box(Rect2(p + Vector2(-18 + x * 22, -18 + y * 22), Vector2(14, 14)), Color.TRANSPARENT, 3, INK, 2)
	_text(id.capitalize(), p + Vector2(0, 53), 20, INK, false, true)

func _draw_gallery(room: Vector2) -> void:
	var mid: float = room.x * 0.5
	_text("Your gardens", Vector2(mid, 245), 34, INK, true, true)
	_text("%d of %d in bloom" % [completed.size(), levels.size()], Vector2(mid, 286), 22, MUTED, false, true)
	for i: int in range(15):
		var index: int = page * 15 + i
		var rect: Rect2 = Rect2(mid - 258 + (i % 3) * 180, 350 + (i / 3) * 130, 156, 105)
		var done: bool = completed.has(str(index))
		_round_box(rect, Color("dce8d6") if done else Color("ebece2"), 20)
		_text(str(index + 1), rect.get_center() + Vector2(0, 9), 30, INK, true, true)
		if done:
			draw_circle(rect.position + Vector2(134, 21), 5, COLORS[0], true, -1.0, true)
		buttons.append({"id": "level_" + str(index), "rect": rect})
	_button("page", "Gardens 16-30" if page == 0 else "Gardens 1-15", Rect2(mid - 190, room.y - 240, 380, 68))
	_button("close", "Back to garden", Rect2(mid - 190, room.y - 148, 380, 68), true)

func _draw_win(room: Vector2) -> void:
	# The sheet covers the play controls; do not leave their hit targets active.
	buttons = buttons.filter(func(button: Dictionary) -> bool: return button.id == "settings")
	var mid: float = room.x * 0.5
	var y: float = room.y - 290
	_round_box(Rect2(mid - 285, y, 570, 202), Color("faf9f3"), 25, Color("c9d5c0"), 1)
	_text("A small garden, grown.", Vector2(mid, y + 48), 29, INK, true, true)
	_text("%d turns. %s" % [moves, "The shortest route." if moves == int(level.par) else "Try %d next time." % int(level.par)], Vector2(mid, y + 84), 21, MUTED, false, true)
	_button("next", "Next garden" if current < levels.size() - 1 else "Finish", Rect2(mid - 250, y + 110, 250, 65), true)
	_button("levels", "Gardens", Rect2(mid + 20, y + 110, 230, 65))

func _draw_sheet(room: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, room), Color(0.13, 0.2, 0.16, 0.25))
	buttons.clear()
	var mid: float = room.x * 0.5
	var y: float = maxf(210, room.y * 0.5 - 360)
	_round_box(Rect2(mid - 302, y, 604, 720), BG, 32)
	var title: String = "Settings" if screen == "settings" else ("How to grow" if screen == "help" else "The grove is yours.")
	_text(title, Vector2(mid, y + 70), 34, INK, true, true)
	if screen == "settings":
		_button("sound", "Sound  " + ("on" if sound_on else "off"), Rect2(mid - 250, y + 125, 500, 72))
		_button("music", "Music  " + ("on" if music_on else "off"), Rect2(mid - 250, y + 219, 500, 72))
		_button("motion", "Reduced motion  " + ("on" if reduced_motion else "off"), Rect2(mid - 250, y + 313, 500, 72))
		_button("help", "How to play", Rect2(mid - 250, y + 407, 500, 72))
		_text("Hinge Grove / experiment 0.1", Vector2(mid, y + 540), 20, MUTED, false, true)
		_text("Music and drawings made for this garden.", Vector2(mid, y + 573), 18, MUTED, false, true)
	elif screen == "help":
		var lines: Array[String] = ["1. Tap a seed to hold it in place.", "2. Tap a marked spot to swing its partner.", "3. Put both seeds on matching soil.", "A seed on its soil takes root.", "Roots stay put. Stones block a swing.", "A stem needs room around the corner.", "Planting too soon can close a route.", "Undo and hints are always free.", "Keyboard: arrows + Enter, Z, R, H."]
		for i: int in range(lines.size()):
			_text(lines[i], Vector2(mid - 251, y + 140 + i * 48), 22)
	else:
		_text("Thirty little gardens.", Vector2(mid, y + 185), 27, INK, false, true)
		_text("Every seed found its place.", Vector2(mid, y + 232), 27, INK, false, true)
		_text("Thank you for trying this experiment.", Vector2(mid, y + 335), 23, MUTED, false, true)
		_button("levels", "Visit your gardens", Rect2(mid - 220, y + 426, 440, 72), true)
	_button("close", "Back", Rect2(mid - 120, y + 615, 240, 66), true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_unlock_audio()
		if event.is_action_pressed("back"):
			screen = "play"
			_clear_selection()
		elif screen == "play" and animation.is_empty():
			if event.is_action_pressed("undo"):
				_undo()
			elif event.is_action_pressed("retry"):
				_load_level(current)
			elif event.is_action_pressed("hint"):
				_hint()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				if solved:
					_action("next")
				else:
					_tap(_cell(cursor))
			else:
				keyboard_visible = true
				if event.keycode == KEY_LEFT:
					cursor = maxi(0, cursor - 1)
				elif event.keycode == KEY_RIGHT:
					cursor = mini(15, cursor + 1)
				elif event.keycode == KEY_UP:
					cursor = maxi(0, cursor - 4)
				elif event.keycode == KEY_DOWN:
					cursor = mini(15, cursor + 4)
	if event is InputEventScreenTouch:
		if event.pressed and touch_id < 0:
			touch_id = event.index
			_begin(event.position)
		elif not event.pressed and event.index == touch_id:
			_end(event.position)
			touch_id = -1
	elif event is InputEventScreenDrag and event.index == touch_id:
		gesture_end = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and touch_id < 0:
		if event.pressed:
			_begin(event.position)
		else:
			_end(event.position)
	elif event is InputEventMouseMotion and gesture_active and touch_id < 0:
		gesture_end = event.position

func _begin(p: Vector2) -> void:
	_unlock_audio()
	gesture_start = p
	gesture_end = p
	gesture_active = true
	keyboard_visible = false

func _end(p: Vector2) -> void:
	if not gesture_active:
		return
	gesture_active = false
	if gesture_start.distance_to(p) < 38:
		_tap(p)
	elif screen == "play" and animation.is_empty() and not solved:
		# Drag a moving seed; its partner is the hinge.
		for i: int in range(state.size()):
			for end: int in range(2):
				if _cell(int(state[i][end])).distance_to(gesture_start) < 49:
					var pin: int = int(state[i][1 - end])
					for choice: Dictionary in Puzzle.options(level, state, i, pin):
						if _cell(int(choice.to)).distance_to(p) < 55:
							_move([i, pin, choice.turn])
							return
		_notice("Swing to a neighbouring spot. Corners need room.")

func _tap(p: Vector2) -> void:
	if not animation.is_empty():
		return
	for button: Dictionary in buttons:
		var rect: Rect2 = button.rect
		if rect.has_point(p):
			_action(String(button.id))
			return
	if screen != "play" or solved:
		return
	for choice: Dictionary in choices:
		if _cell(int(choice.to)).distance_to(p) < 51:
			_move([choice.piece, choice.pivot, choice.turn])
			return
	for i: int in range(state.size()):
		for cell_value: Variant in state[i]:
			var cell: int = int(cell_value)
			if _cell(cell).distance_to(p) < 50:
				selected_piece = i
				selected_pivot = cell
				choices = Puzzle.options(level, state, i, cell)
				hint_move.clear()
				if choices.is_empty():
					_notice("No room to swing. Try the other seed or undo.")
				return
	_clear_selection()

func _move(move: Array) -> void:
	var next: Array = Puzzle.apply(level, state, move)
	if next.is_empty() or solved:
		return
	for choice: Dictionary in Puzzle.options(level, state, int(move[0]), int(move[1])):
		if int(choice.turn) == int(move[2]):
			animation = choice.duplicate()
			break
	history.append(state.duplicate(true))
	state = next
	moves += 1
	anim_time = 0.0
	_clear_selection()
	_sound("turn")
	_publish()

func _finish_move() -> void:
	var previous: Array = history.back() if not history.is_empty() else state
	for i: int in range(state.size()):
		if state[i] == level.goals[i] and previous[i] != state[i]:
			_sound("bloom")
		elif state[i] != previous[i]:
			for cell_value: Variant in state[i]:
				if cell_value in level.goals[i] and cell_value not in previous[i]:
					_sound("root")
					_notice("Rooted. This seed now holds its place.")
	solved = Puzzle.won(level, state)
	if solved:
		bloom_time = 0.0
		var old: int = int(completed.get(str(current), 9999))
		completed[str(current)] = mini(old, moves)
		_save()
	elif Puzzle.options(level, state).is_empty():
		_notice("No swings left. Undo to make room.")

func _undo() -> void:
	if history.is_empty():
		_notice("Your garden is back at the beginning.")
		return
	state = history.pop_back()
	moves = maxi(0, moves - 1)
	solved = false
	animation.clear()
	_clear_selection()
	_sound("undo")
	_notice("One turn back.")

func _hint() -> void:
	if solved:
		return
	var result: Dictionary = Puzzle.solve(level, state)
	if result.status == "stuck":
		_notice("This planting blocks the route. Undo a turn.")
	elif result.status == "limit":
		_notice("Try undoing a turn, then ask again.")
	elif not result.route.is_empty():
		var move: Array = result.route[0]
		selected_piece = int(move[0])
		selected_pivot = int(move[1])
		choices.clear()
		for choice: Dictionary in Puzzle.options(level, state, selected_piece, selected_pivot):
			if int(choice.turn) == int(move[2]):
				choices.append(choice)
		hint_move = move
		_notice("Hold the ringed seed. Swing along the curve.")

func _notice(text: String) -> void:
	message = text
	message_time = 4.0

func _action(id: String) -> void:
	match id:
		"undo": _undo()
		"hint": _hint()
		"reset": _load_level(current)
		"levels":
			screen = "levels"
			page = current / 15
		"settings": screen = "settings"
		"help": screen = "help"
		"close": screen = "play"
		"page": page = 1 - page
		"next":
			if solved:
				if current == levels.size() - 1:
					screen = "ending"
				else:
					_load_level(current + 1)
		"sound":
			sound_on = not sound_on
			_save()
		"music":
			music_on = not music_on
			if music_on and music.stream != null:
				music.play()
			else:
				music.stop()
			_save()
		"motion":
			reduced_motion = not reduced_motion
			_save()
		_:
			if id.begins_with("level_"):
				_load_level(int(id.trim_prefix("level_")))
	_publish()
	queue_redraw()

func _publish() -> void:
	if not OS.has_feature("web") or level.is_empty():
		return
	var positions: Array = []
	for cell: int in range(16):
		var p: Vector2 = _cell(cell)
		positions.append([p.x, p.y])
	var data: Dictionary = {"level": current + 1, "count": levels.size(), "state": state, "moves": moves, "won": solved, "screen": screen, "selected": selected_pivot, "choices": choices, "music": music_on, "sound": sound_on, "motion": reduced_motion, "busy": not animation.is_empty(), "message": message if message_time > 0 else "", "cells": positions, "viewport": [get_viewport_rect().size.x, get_viewport_rect().size.y]}
	var regions: Array = []
	for button: Dictionary in buttons:
		var rect: Rect2 = button.rect
		regions.append({"id": button.id, "center": [rect.get_center().x, rect.get_center().y]})
	data["buttons"] = regions
	var json: String = JSON.stringify(data)
	if json != last_debug:
		JavaScriptBridge.eval("window.hingeState=" + json + ";")
		last_debug = json
