extends Node2D

const Puzzle = preload("res://scripts/puzzle.gd")
const Growth = preload("res://scripts/growth.gd")
const Session = preload("res://scripts/session.gd")
const FONT_FILE = preload("res://assets/fonts/Manrope.ttf")
const SAVE_PATH: String = "user://hinge-grove-v1.cfg"
const PITCH: float = 144.0
const SWING_SECONDS: float = 0.28
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
var selected_seed: int = -1
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
var garden: Growth = Growth.new()
var saved_run: Dictionary = {}
var saved_runs: Dictionary = {}
var pressed_button: String = ""
var dragging: bool = false
var drag_piece: int = -1
var drag_seed: int = -1
var drag_angle: float = 0.0
var drag_choice: Dictionary = {}
var blocked_cells: Array = []
var blocked_time: float = 0.0
var route_stuck: bool = false
var guided: bool = true
var previous_screen: String = "play"


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
	_load_level(current, true)
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
	var loaded: bool = false
	# IndexedDB flushes asynchronously. Read the synchronous browser snapshot first.
	if OS.has_feature("web"):
		var snapshot: Variant = JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('hinge-grove-save-v2')}catch(e){return null}})()")
		if snapshot is String and not snapshot.is_empty():
			loaded = config.parse(snapshot) == OK
	if not loaded:
		config = ConfigFile.new()
		loaded = config.load(SAVE_PATH) == OK
	if loaded:
		current = clampi(int(config.get_value("progress", "level", 0)), 0, levels.size() - 1)
		var saved: Variant = config.get_value("progress", "completed", {})
		if saved is Dictionary:
			for key: Variant in saved:
				var index: int = String(key).to_int()
				if index >= 0 and index < levels.size():
					completed[str(index)] = int(saved[key])
		var runs: Variant = config.get_value("runs", "by_level", {})
		if runs is Dictionary:
			saved_runs = runs
		var run: Variant = config.get_value("session", "run", {})
		if run is Dictionary:
			saved_run = run
			if not run.is_empty():
				saved_runs[str(current)] = run
		sound_on = bool(config.get_value("settings", "sound", true))
		music_on = bool(config.get_value("settings", "music", true))
		reduced_motion = bool(config.get_value("settings", "motion", false))
		guided = bool(config.get_value("settings", "guidance", true))

func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "level", current)
	config.set_value("progress", "completed", completed)
	config.set_value("settings", "sound", sound_on)
	config.set_value("settings", "music", music_on)
	config.set_value("settings", "motion", reduced_motion)
	config.set_value("settings", "guidance", guided)
	if not level.is_empty():
		saved_runs[str(current)] = {"revision": 1, "level": current, "state": state.duplicate(true), "history": history.duplicate(true), "moves": moves}
		config.set_value("runs", "by_level", saved_runs)
	config.save(SAVE_PATH)
	if OS.has_feature("web"):
		# A refresh immediately after a move must not race the filesystem flush.
		var snapshot: String = JSON.stringify(config.encode_to_text())
		JavaScriptBridge.eval("(()=>{try{localStorage.setItem('hinge-grove-save-v2'," + snapshot + ");return true}catch(e){return false}})()")

func _load_level(index: int, resume: bool = true) -> void:
	current = clampi(index, 0, levels.size() - 1)
	level = levels[current]
	state = Puzzle.initial(level)
	moves = 0
	cursor = 0
	history.clear()
	_clear_selection()
	_clear_gesture()
	animation.clear()
	message_time = 0.0
	blocked_time = 0.0
	route_stuck = false
	screen = "play"
	if resume:
		var recovered: Dictionary = Session.recover(level, saved_runs.get(str(current), {}), current)
		if not recovered.is_empty():
			state = recovered.state
			history = recovered.history
			moves = recovered.moves
	saved_run.clear()
	solved = Puzzle.won(level, state)
	bloom_time = 3.0 if solved else 0.0
	garden.reset(level, state)
	if solved:
		completed[str(current)] = mini(int(completed.get(str(current), 9999)), moves)
	elif moves > 0:
		_check_route()
	_save()
	_publish()
	queue_redraw()

func _clear_selection() -> void:
	selected_piece = -1
	selected_pivot = -1
	selected_seed = -1
	choices.clear()
	hint_move.clear()

func _process(delta: float) -> void:
	elapsed += delta
	message_time = maxf(0.0, message_time - delta)
	blocked_time = maxf(0.0, blocked_time - delta)
	garden.advance(delta, reduced_motion)
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
	var target: Rect2 = rect
	var extra: float = maxf(0.0, 96.0 - rect.size.y) * 0.5
	target = target.grow_individual(0.0, extra, 0.0, extra)
	buttons.append({"id": id, "rect": target})
	_round_box(rect, INK if primary else Color("e6eadd"), 20)
	_text(label, rect.get_center() + Vector2(0, 10), 28, BG if primary else INK, primary, true)

func _draw() -> void:
	if level.is_empty():
		return
	buttons.clear()
	var room: Vector2 = get_viewport_rect().size
	var mid: float = room.x * 0.5
	draw_rect(Rect2(Vector2.ZERO, room), BG)
	_text("Hinge Grove", Vector2(mid, 98), 38, INK, true, true)
	buttons.append({"id": "settings", "rect": Rect2(room.x - 116, 43, 100, 100)})
	for dx: int in [-11, 0, 11]:
		draw_circle(Vector2(room.x - 66 + dx, 93), 3.2, INK, true, -1.0, true)
	if screen == "levels":
		_draw_gallery(room)
		return
	var chapter: String = "First turns" if current < 6 else ("Make room" if current < 18 else "Shared ground")
	_text("%s  /  Garden %02d" % [chapter, current + 1], Vector2(mid, 157), 28, MUTED, false, true)
	var coach: Array[String] = _coach_lines()
	var coach_y: float = _origin().y - 158.0
	_text(coach[0], Vector2(mid, coach_y), 29, INK, true, true)
	_text(coach[1], Vector2(mid, coach_y + 40), 25, MUTED, false, true)
	_draw_board()
	var bottom: float = _origin().y + PITCH * 3.0 + 88.0
	if route_stuck and not solved:
		_button("recover", "Undo blocked planting", Rect2(mid - 245, bottom + 26, 490, 80), true)
	else:
		_text("%d of %d plants grown" % [_grown_count(), state.size()], Vector2(mid, bottom + 50), 28, INK, false, true)
		for i: int in range(state.size()):
			var p: Vector2 = Vector2(mid + (i - (state.size() - 1) * 0.5) * 30.0, bottom + 79)
			draw_circle(p, 7.0, COLORS[i] if state[i] == level.goals[i] else Color("ced8c5"), true, -1.0, true)
	var row_y: float = _controls_y()
	for i: int in range(4):
		var x: float = mid - 234 + i * 156
		_draw_action(["undo", "hint", "reset", "levels"][i], Vector2(x, row_y))
	if solved and bloom_time > (0.15 if reduced_motion else 1.15):
		_draw_win(room)
	if screen == "settings" or screen == "help" or screen == "ending" or screen == "restart":
		_draw_sheet(room)

func _draw_board() -> void:
	var origin: Vector2 = _origin()
	var board_rect: Rect2 = Rect2(origin - Vector2(84, 84), Vector2(PITCH * 3 + 168, PITCH * 3 + 168))
	_round_box(Rect2(board_rect.position + Vector2(0, 9), board_rect.size), Color("dce2d1"), 42)
	var garden_ratio: float = 0.0
	for age: float in garden.roots.values():
		garden_ratio += clampf(age / 0.8, 0.0, 1.0) / float(state.size() * 2)
	_round_box(board_rect, Color("edf0e5").lerp(Color("e2edd8"), garden_ratio), 42)
	for cell: int in range(int(level.size) * int(level.size)):
		var p: Vector2 = _cell(cell)
		if cell in level.walls:
			_draw_rock(p)
		else:
			draw_circle(p, 3.8, Color("b4c5aa"), true, -1.0, true)
	for i: int in range(level.goals.size()):
		for cell: int in level.goals[i]:
			var p: Vector2 = _cell(cell)
			draw_circle(p, 40.0, PALE[i], true, -1.0, true)
			draw_arc(p, 40.0, 0, TAU, 48, COLORS[i].lightened(0.08), 2.8, true)
			_mark(p, i, COLORS[i].darkened(0.12), 12.0)
			if cell in state[i]:
				var age: float = garden.root_age(i, cell)
				if age < 0.9 and not reduced_motion:
					draw_arc(p, 40.0 + age * 39.0, 0, TAU, 48, Color(COLORS[i], (1.0 - age / 0.9) * 0.35), 3.0, true)
	var shown: Array = choices
	var guide: Array = _guide_move() if selected_seed < 0 else []
	var guide_seed: int = -1
	if not guide.is_empty():
		var options: Array = Puzzle.options(level, state, int(guide[0]), int(guide[1]))
		shown = options.filter(func(c: Dictionary) -> bool: return int(c.turn) == int(guide[2]))
		if not shown.is_empty():
			guide_seed = int(shown[0].from)
	for choice: Dictionary in shown:
		_draw_choice(choice, not drag_choice.is_empty() and int(drag_choice.to) == int(choice.to))
	for i: int in range(state.size()):
		var positions: Array[Vector2] = [_cell(int(state[i][0])), _cell(int(state[i][1]))]
		var moving_cell: int = -1
		if not animation.is_empty() and int(animation.piece) == i:
			var pivot: Vector2 = _cell(int(animation.pivot))
			var start: Vector2 = _cell(int(animation.from))
			var amount: float = clampf(anim_time / (0.06 if reduced_motion else SWING_SECONDS), 0, 1)
			var ease: float = amount * amount * (3.0 - 2.0 * amount)
			var relative: float = lerpf(float(animation.get("start_angle", 0.0)), PI * 0.5 * int(animation.turn), ease)
			moving_cell = int(animation.to)
			positions[state[i].find(moving_cell)] = pivot + (start - pivot).rotated(relative)
		elif dragging and drag_piece == i:
			var pivot: Vector2 = _cell(selected_pivot)
			moving_cell = drag_seed
			positions[state[i].find(drag_seed)] = pivot + (_cell(drag_seed) - pivot).rotated(drag_angle)
		var flower: bool = state[i] == level.goals[i] and moving_cell < 0
		_draw_stem(positions[0], positions[1], COLORS[i], flower, i)
		for end: int in range(2):
			var cell: int = int(state[i][end])
			var locked: bool = cell in level.goals[i] and cell != moving_cell
			_draw_seed(positions[end], i, locked, flower, cell)
		if selected_piece == i and selected_seed >= 0:
			var pin: Vector2 = _cell(selected_pivot)
			draw_circle(pin + Vector2(27, 28), 13.0, INK, true, -1.0, true)
			draw_circle(pin + Vector2(27, 28), 5.0, BG, true, -1.0, true)
			if not dragging:
				var selected: Vector2 = _cell(selected_seed)
				draw_arc(selected, 47.0, 0, TAU, 56, INK, 3.0, true)
	if guide_seed >= 0:
		var pulse: float = 0.0 if reduced_motion else (sin(elapsed * 3.5) + 1.0) * 3.0
		draw_arc(_cell(guide_seed), 47.0 + pulse, 0, TAU, 56, COLORS[0], 3.5, true)
	if blocked_time > 0.0:
		for cell: int in blocked_cells:
			var p: Vector2 = _cell(cell)
			draw_arc(p, 51.0, 0, TAU, 48, Color("ae573d"), 4.0, true)
	if keyboard_visible:
		_round_box(Rect2(_cell(cursor) - Vector2(54, 54), Vector2(108, 108)), Color.TRANSPARENT, 18, INK, 2)
	_draw_particles()

func _draw_rock(p: Vector2) -> void:
	var points: PackedVector2Array = [p + Vector2(-38, 8), p + Vector2(-25, -26), p + Vector2(7, -35), p + Vector2(36, -9), p + Vector2(34, 25), p + Vector2(-10, 33)]
	draw_colored_polygon(points, Color("b5beb0"))
	points.append(points[0])
	draw_polyline(points, Color("879783"), 2.0, true)
	draw_line(p + Vector2(-16, -13), p + Vector2(8, -23), Color("d7ded0"), 3.0, true)

func _draw_stem(a: Vector2, b: Vector2, color: Color, rooted: bool, piece: int) -> void:
	var mid: Vector2 = a.lerp(b, 0.5)
	var d: Vector2 = (b - a).normalized()
	var normal: Vector2 = Vector2(-d.y, d.x)
	var bend: float = 0.0
	if not reduced_motion and not animation.is_empty() and int(animation.piece) == piece:
		bend = sin(clampf(anim_time / SWING_SECONDS, 0, 1) * PI) * 14.0
	var path: PackedVector2Array = []
	for step: int in range(17):
		var t: float = float(step) / 16.0
		path.append(a.lerp(b, t) + normal * sin(t * PI) * bend)
	draw_polyline(path, Color(color, 0.22), 19.0, true)
	draw_polyline(path, color.lightened(0.23), 11.0, true)
	var grow: float = Growth.pop(garden.flower_age(piece) / 0.8) if rooted else 0.35
	for side: int in [-1, 1]:
		var base: Vector2 = mid + d * side * 12.0 + normal * bend
		var sway: float = 0.0 if reduced_motion else sin(elapsed * 2.0 + piece + side) * 3.0
		var leaf: PackedVector2Array = [base - d * 8, base + normal * side * (17.0 + 18.0 * grow + sway) - d * 7, base + normal * side * (23.0 + 18.0 * grow) + d * 17, base + d * 13]
		draw_colored_polygon(leaf, color.lightened(0.25 if rooted else 0.4))
		draw_line(base, base + normal * side * (17.0 + 18.0 * grow) + d * 9, color.lightened(0.12), 1.8, true)

func _draw_seed(p: Vector2, kind: int, locked: bool, flower: bool, cell: int) -> void:
	var color: Color = COLORS[kind]
	var age: float = garden.root_age(kind, cell)
	var bounce: float = 0.0 if reduced_motion or not locked else sin(age * 14.0) * exp(-age * 5.0) * 0.14
	draw_set_transform(p, 0.0, Vector2(1.0 + bounce, 1.0 - bounce * 0.7))
	if locked:
		var growth: float = 1.0 if reduced_motion else clampf(age / 0.65, 0, 1)
		for root: int in range(3):
			var angle: float = PI * 0.22 + root * PI * 0.28
			var from: Vector2 = Vector2.from_angle(angle) * 32.0
			var to: Vector2 = Vector2.from_angle(angle) * (38.0 + growth * 24.0)
			var middle: Vector2 = from.lerp(to, 0.55) + Vector2((root - 1) * 6.0, 0)
			draw_polyline(PackedVector2Array([from, middle, to]), color.lightened(0.15), 3.3, true)
		draw_arc(Vector2.ZERO, 41.0, 0, TAU, 48, Color(color, 0.7), 2.5, true)
	if flower:
		var flower_age: float = garden.flower_age(kind)
		var sway: float = 0.0 if reduced_motion else sin(elapsed * 1.5 + kind) * 0.025
		for petal: int in range(6 + kind):
			var amount: float = 1.0 if reduced_motion else Growth.pop((flower_age - petal * 0.055) / 0.5)
			var angle: float = TAU * petal / (6 + kind) - PI * 0.5 + sway + (1.0 - clampf(flower_age, 0, 1)) * 0.4
			var offset: Vector2 = Vector2.from_angle(angle) * 31.0 * amount
			if amount > 0.0:
				draw_circle(offset + Vector2(0, 4), 23.0 * amount, Color(0.18, 0.3, 0.2, 0.09), true, -1.0, true)
				draw_circle(offset, 23.0 * amount, color.lightened(0.35 + (petal % 2) * 0.08), true, -1.0, true)
		draw_circle(Vector2.ZERO, 25.0, color, true, -1.0, true)
		_mark(Vector2.ZERO, kind, Color("fff7dd"), 11.0)
	else:
		draw_circle(Vector2(0, 6), 36.0, Color(0.18, 0.3, 0.2, 0.14), true, -1.0, true)
		draw_circle(Vector2.ZERO, 36.0, color, true, -1.0, true)
		draw_arc(Vector2(-1, -1), 28.0, PI * 1.07, PI * 1.64, 24, color.lightened(0.32), 3.0, true)
		_mark(Vector2.ZERO, kind, Color("fff9e9"), 12.0)
	draw_set_transform(Vector2.ZERO)

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
	_text(id.capitalize(), p + Vector2(0, 57), 25, INK, false, true)

func _draw_gallery(room: Vector2) -> void:
	var mid: float = room.x * 0.5
	_text("Your gardens", Vector2(mid, 230), 36, INK, true, true)
	_text("%d of %d in bloom" % [completed.size(), levels.size()], Vector2(mid, 276), 27, MUTED, false, true)
	_text("Pick any garden. Bloomed gardens replay.", Vector2(mid, 317), 24, MUTED, false, true)
	for i: int in range(15):
		var index: int = page * 15 + i
		var rect: Rect2 = Rect2(mid - 258 + (i % 3) * 180, 362 + (i / 3) * 130, 156, 105)
		var done: bool = completed.has(str(index))
		_round_box(rect, Color("dce8d6") if done else Color("ebece2"), 20, INK if index == current else Color.TRANSPARENT, 2 if index == current else 0)
		_text(str(index + 1), rect.get_center() + Vector2(0, 10), 32, INK, true, true)
		if done:
			var center: Vector2 = rect.position + Vector2(131, 22)
			for petal: int in range(5):
				draw_circle(center + Vector2.from_angle(TAU * petal / 5.0) * 6.0, 5.0, COLORS[0].lightened(0.3), true, -1.0, true)
			draw_circle(center, 4.0, COLORS[0], true, -1.0, true)
		elif saved_runs.has(str(index)) and int(saved_runs[str(index)].get("moves", 0)) > 0:
			draw_arc(rect.position + Vector2(131, 22), 8.0, -PI * 0.5, PI * 1.2, 24, COLORS[0], 3, true)
		buttons.append({"id": "level_" + str(index), "rect": rect})
	_button("page", "Gardens 16-30" if page == 0 else "Gardens 1-15", Rect2(mid - 210, room.y - 234, 420, 82))
	_button("close", "Back to garden", Rect2(mid - 210, room.y - 118, 420, 82), true)

func _draw_win(room: Vector2) -> void:
	buttons = buttons.filter(func(button: Dictionary) -> bool: return button.id == "settings")
	var mid: float = room.x * 0.5
	var bottom: float = _origin().y + PITCH * 3.0 + 88.0
	var y: float = minf(room.y - 270.0, bottom + 108.0)
	_round_box(Rect2(mid - 300, y, 600, 230), Color("faf9f3"), 28, Color("c9d5c0"), 1)
	_text("Look what you grew.", Vector2(mid, y + 49), 32, INK, true, true)
	_text("%d turns  /  shortest route %d" % [moves, int(level.par)], Vector2(mid, y + 91), 25, MUTED, false, true)
	var label: String = "Finish" if completed.size() >= levels.size() else "Next garden"
	_button("next", label, Rect2(mid - 270, y + 120, 270, 82), true)
	_button("levels", "Gardens", Rect2(mid + 24, y + 120, 246, 82))

func _draw_sheet(room: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, room), Color(0.13, 0.2, 0.16, 0.25))
	buttons.clear()
	var mid: float = room.x * 0.5
	if screen == "restart":
		var top: float = room.y * 0.5 - 190.0
		_round_box(Rect2(mid - 310, top, 620, 380), BG, 30)
		_text("Start this garden again?", Vector2(mid, top + 81), 32, INK, true, true)
		_text("Your current planting will be cleared.", Vector2(mid, top + 147), 25, MUTED, false, true)
		_button("close", "Keep playing", Rect2(mid - 278, top + 238, 270, 84), true)
		_button("restart_yes", "Restart", Rect2(mid + 12, top + 238, 266, 84))
		return
	var y: float = maxf(180.0, room.y * 0.5 - 435.0)
	_round_box(Rect2(mid - 310, y, 620, 870), BG, 32)
	var title: String = "Settings" if screen == "settings" else ("How to grow" if screen == "help" else "The grove is yours.")
	_text(title, Vector2(mid, y + 74), 36, INK, true, true)
	if screen == "settings":
		_button("sound", "Sound  " + ("on" if sound_on else "off"), Rect2(mid - 265, y + 122, 530, 84))
		_button("music", "Music  " + ("on" if music_on else "off"), Rect2(mid - 265, y + 232, 530, 84))
		_button("motion", "Reduced motion  " + ("on" if reduced_motion else "off"), Rect2(mid - 265, y + 342, 530, 84))
		_button("guidance", "Opening guidance  " + ("on" if guided else "off"), Rect2(mid - 265, y + 452, 530, 84))
		_button("help", "How to play", Rect2(mid - 265, y + 562, 530, 84))
	elif screen == "help":
		var lines: Array[String] = ["Tap the seed you want to move.", "Then tap a marked landing spot.", "You can also drag the same seed.", "Its partner stays in place as the pivot.", "Matching soil makes a seed take root.", "Move its partner to finish the plant.", "The whole swing needs an empty corner.", "Undo and hints are always free.", "Keyboard: arrows, Enter, Z, R, H."]
		for i: int in range(lines.size()):
			_text(lines[i], Vector2(mid - 267, y + 148 + i * 58), 26)
	else:
		_text("Thirty gardens, all in bloom.", Vector2(mid, y + 220), 30, INK, false, true)
		_text("Your patience made this grove.", Vector2(mid, y + 276), 27, MUTED, false, true)
		_text("Thank you for growing it.", Vector2(mid, y + 377), 27, MUTED, false, true)
		_button("levels", "Visit your gardens", Rect2(mid - 245, y + 512, 490, 84), true)
	_button("close", "Back", Rect2(mid - 145, y + 746, 290, 84), true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_unlock_audio()
		if event.is_action_pressed("back"):
			_action("close")
			_clear_selection()
			_clear_gesture()
		elif screen == "play" and animation.is_empty():
			if event.is_action_pressed("undo"):
				_undo()
			elif event.is_action_pressed("retry"):
				_action("reset")
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
		_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and touch_id < 0:
		if event.pressed:
			_begin(event.position)
		else:
			_end(event.position)
	elif event is InputEventMouseMotion and gesture_active and touch_id < 0:
		_drag(event.position)

func _begin(p: Vector2) -> void:
	_unlock_audio()
	_clear_gesture()
	gesture_start = p
	gesture_end = p
	gesture_active = true
	keyboard_visible = false
	for button: Dictionary in buttons:
		if Rect2(button.rect).has_point(p):
			pressed_button = String(button.id)
			return
	if screen != "play" or solved or not animation.is_empty():
		return
	var seed: Array = _seed_at(p)
	if not seed.is_empty():
		var piece: int = int(seed[0])
		var cell: int = int(seed[1])
		_select_seed(piece, cell)
		if cell not in level.goals[piece]:
			drag_piece = piece
			drag_seed = cell

func _end(p: Vector2) -> void:
	if not gesture_active:
		return
	if not pressed_button.is_empty():
		var id: String = pressed_button
		var inside: bool = false
		for button: Dictionary in buttons:
			if button.id == id and Rect2(button.rect).has_point(p):
				inside = true
		_clear_gesture()
		if inside:
			_action(id)
		return
	if dragging:
		_drag(p)
		var choice: Dictionary = drag_choice.duplicate()
		var angle: float = drag_angle
		if choice.is_empty():
			_explain_block(p)
			_clear_gesture()
		else:
			_move([choice.piece, choice.pivot, choice.turn], angle)
		return
	var small: bool = gesture_start.distance_to(p) < 28.0
	_clear_gesture()
	if small:
		_tap(p)

func _tap(p: Vector2) -> void:
	if not animation.is_empty():
		return
	for button: Dictionary in buttons:
		if Rect2(button.rect).has_point(p):
			_action(String(button.id))
			return
	if screen != "play" or solved:
		return
	for choice: Dictionary in choices:
		if _cell(int(choice.to)).distance_to(p) < 60.0:
			_move([choice.piece, choice.pivot, choice.turn])
			return
	var seed: Array = _seed_at(p)
	if not seed.is_empty():
		_select_seed(int(seed[0]), int(seed[1]))
		return
	if selected_seed >= 0:
		_explain_block(p)
		return
	_clear_selection()

func _move(move: Array, start_angle: float = 0.0) -> void:
	var next: Array = Puzzle.apply(level, state, move)
	if next.is_empty() or solved:
		return
	for choice: Dictionary in Puzzle.options(level, state, int(move[0]), int(move[1])):
		if int(choice.turn) == int(move[2]):
			animation = choice.duplicate()
			animation["start_angle"] = start_angle
			break
	history.append(state.duplicate(true))
	state = next
	moves = history.size()
	anim_time = 0.0
	message_time = 0.0
	_clear_selection()
	_clear_gesture()
	_sound("turn")
	_save()
	_publish()

func _finish_move() -> void:
	var previous: Array = history.back() if not history.is_empty() else state
	garden.changed(level, previous, state, reduced_motion)
	var planted: bool = false
	for i: int in range(state.size()):
		if state[i] == level.goals[i] and previous[i] != state[i]:
			_sound("bloom")
		for cell: int in state[i]:
			if cell in level.goals[i] and cell not in previous[i]:
				planted = true
				if state[i] != level.goals[i]:
					_sound("root")
	solved = Puzzle.won(level, state)
	if solved:
		bloom_time = 0.0
		completed[str(current)] = mini(int(completed.get(str(current), 9999)), moves)
		route_stuck = false
	elif planted:
		_check_route()
		if route_stuck:
			_notice("This planting closes the route.")
		elif current > 0:
			_notice("Roots down. Swing the other seed.")
	_save()

func _undo() -> void:
	if history.is_empty():
		_notice("You are at the beginning of this garden.")
		return
	state = history.pop_back()
	moves = history.size()
	solved = false
	animation.clear()
	_clear_selection()
	_clear_gesture()
	garden.reset(level, state)
	_check_route()
	_sound("undo")
	message_time = 0.0
	_save()

func _hint() -> void:
	if solved:
		return
	var result: Dictionary = Puzzle.solve(level, state)
	if result.status == "stuck":
		route_stuck = true
		_notice("This planting blocks the route.")
	elif result.status == "limit":
		_notice("Try undoing a turn, then ask again.")
	elif not result.route.is_empty():
		var move: Array = result.route[0]
		var piece: int = int(move[0])
		var pivot: int = int(move[1])
		var seed: int = int(state[piece][0]) if int(state[piece][1]) == pivot else int(state[piece][1])
		_select_seed(piece, seed)
		choices = choices.filter(func(c: Dictionary) -> bool: return int(c.turn) == int(move[2]))
		hint_move = move
		_notice("Move the ringed seed along the curve.")

func _notice(text: String) -> void:
	message = text
	message_time = 4.0

func _action(id: String) -> void:
	match id:
		"undo": _undo()
		"recover": _recover_route()
		"hint": _hint()
		"reset":
			if moves > 0:
				screen = "restart"
			else:
				_load_level(current, false)
		"restart_yes": _load_level(current, false)
		"levels":
			screen = "levels"
			page = current / 15
		"settings":
			previous_screen = screen
			screen = "settings"
		"help":
			previous_screen = screen
			screen = "help"
		"close":
			screen = "settings" if screen == "help" and previous_screen == "settings" else "play"
		"page": page = 1 - page
		"next":
			if solved:
				var next: int = Session.next_garden(levels.size(), current, completed)
				if next < 0:
					screen = "ending"
				else:
					_load_level(next)
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
			garden.advance(0.0, reduced_motion)
			_save()
		"guidance":
			guided = not guided
			_save()
		_:
			if id.begins_with("level_"):
				var index: int = int(id.trim_prefix("level_"))
				if index == current and not solved:
					screen = "play"
				else:
					_load_level(index, not completed.has(str(index)))
	_clear_gesture()
	_publish()
	queue_redraw()

func _publish() -> void:
	if not OS.has_feature("web") or level.is_empty():
		return
	var positions: Array = []
	for cell: int in range(16):
		var p: Vector2 = _cell(cell)
		positions.append([p.x, p.y])
	var data: Dictionary = {"version": 2, "level": current + 1, "count": levels.size(), "state": state, "moves": moves, "won": solved, "screen": screen, "selected": selected_seed, "pivot": selected_pivot, "choices": choices, "music": music_on, "sound": sound_on, "motion": reduced_motion, "guidance": guided, "busy": not animation.is_empty(), "message": message if message_time > 0 else "", "coach": _coach_lines(), "cells": positions, "viewport": [get_viewport_rect().size.x, get_viewport_rect().size.y], "roots": _rooted_count(), "grown": _grown_count(), "stuck": route_stuck, "history": history.size(), "particles": garden.particles.size(), "preview": {"active": dragging, "angle": drag_angle, "to": drag_choice.get("to", -1), "cell": drag_seed}, "completed": completed.size()}
	var regions: Array = []
	for button: Dictionary in buttons:
		var rect: Rect2 = button.rect
		regions.append({"id": button.id, "center": [rect.get_center().x, rect.get_center().y], "size": [rect.size.x, rect.size.y]})
	data["buttons"] = regions
	var json: String = JSON.stringify(data)
	if json != last_debug:
		JavaScriptBridge.eval("window.hingeState=" + json + ";")
		last_debug = json

func _clear_gesture() -> void:
	pressed_button = ""
	gesture_active = false
	dragging = false
	drag_piece = -1
	drag_seed = -1
	drag_angle = 0.0
	drag_choice.clear()

func _grown_count() -> int:
	var count: int = 0
	for i: int in range(state.size()):
		if state[i] == level.goals[i]:
			count += 1
	return count

func _rooted_count() -> int:
	var count: int = 0
	for i: int in range(state.size()):
		for cell: int in state[i]:
			if cell in level.goals[i]:
				count += 1
	return count

func _controls_y() -> float:
	return minf(get_viewport_rect().size.y - 126.0, _origin().y + PITCH * 3.0 + 274.0)

func _guide_move() -> Array:
	if not guided or current != 0 or moves >= 2 or solved:
		return []
	var result: Dictionary = Puzzle.solve(level, state)
	return result.route[0] if result.status == "solved" and not result.route.is_empty() else []

func _coach_lines() -> Array[String]:
	if solved:
		return ["Your garden is in bloom.", "Every seed found its place."]
	if route_stuck:
		return ["This route is closed.", "Undo the planting to make room."]
	if message_time > 0.0:
		return [message, "Undo is always available." if moves > 0 else ""]
	if selected_seed >= 0:
		if selected_seed in level.goals[selected_piece]:
			return ["This seed has roots.", "Move its partner around it."]
		if not drag_choice.is_empty() and int(drag_choice.to) in level.goals[selected_piece]:
			return ["This landing will take root.", "The other seed can still swing around it."]
		return ["Move the selected seed.", "Drag along the curve, or tap a landing spot."]
	if guided and current == 0:
		if _rooted_count() > 0:
			return ["One seed has taken root.", "Move its partner onto the other soil spot."]
		return ["Move the glowing seed.", "Drag it, or tap it and then the marked spot."]
	if guided and current == 1:
		return ["Match each seed to its soil.", "Look for the same colour and symbol."]
	if guided and current == 2:
		return ["Give the whole swing room.", "A stone can block the corner of the arc."]
	return ["Grow every plant on its matching soil.", "Tap or drag the seed you want to move."]

func _check_route() -> void:
	var result: Dictionary = Puzzle.solve(level, state)
	route_stuck = result.status == "stuck"

func _recover_route() -> void:
	if history.is_empty():
		return
	while not history.is_empty():
		state = history.pop_back()
		moves = history.size()
		if Puzzle.solve(level, state).status == "solved":
			break
	solved = false
	route_stuck = false
	animation.clear()
	_clear_selection()
	_clear_gesture()
	garden.reset(level, state)
	_sound("undo")
	_notice("Back before the blocked planting.")
	_save()

func _draw_choice(choice: Dictionary, hovered: bool) -> void:
	var p: Vector2 = _cell(int(choice.pivot))
	var a: float = (_cell(int(choice.from)) - p).angle()
	var path: PackedVector2Array = []
	for step: int in range(25):
		var angle: float = a + PI * 0.5 * int(choice.turn) * float(step) / 24.0
		path.append(p + Vector2.from_angle(angle) * PITCH)
	var color: Color = COLORS[int(choice.piece)]
	draw_polyline(path, Color(color, 0.8 if hovered else 0.46), 4.0 if hovered else 3.0, true)
	var target: Vector2 = _cell(int(choice.to))
	draw_circle(target, 39.0, Color(color, 0.22 if hovered else 0.08), true, -1.0, true)
	draw_arc(target, 39.0, 0, TAU, 48, color, 3.5 if hovered else 2.5, true)
	_mark(target, int(choice.piece), Color(color, 0.6), 11.0)
	var tangent: Vector2 = (path[24] - path[22]).normalized()
	var tip: Vector2 = target - tangent * 44.0
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	draw_colored_polygon(PackedVector2Array([tip, tip - tangent * 15.0 + normal * 8.0, tip - tangent * 15.0 - normal * 8.0]), color)
	if int(choice.to) in level.goals[int(choice.piece)]:
		for dx: int in [-8, 0, 8]:
			draw_line(target + Vector2(dx * 0.5, 44), target + Vector2(dx, 56), color, 2.5, true)

func _draw_particles() -> void:
	if reduced_motion:
		return
	for particle: Dictionary in garden.particles:
		var age: float = float(particle.age)
		var life: float = float(particle.life)
		var p: Vector2 = _cell(int(particle.cell)) + Vector2(particle.velocity) * age + Vector2(0, 110.0 * age * age)
		var alpha: float = clampf((life - age) * 2.8, 0, 0.85)
		var color: Color = Color(COLORS[int(particle.piece)].lightened(0.35), alpha)
		if bool(particle.petal):
			var d: Vector2 = Vector2.from_angle(float(particle.spin) + age * 5.0)
			var n: Vector2 = Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([p + d * 9, p + n * 4, p - d * 9, p - n * 4]), color)
		else:
			draw_circle(p, 3.5, color, true, -1.0, true)

func _seed_at(p: Vector2) -> Array:
	for i: int in range(state.size()):
		for cell: int in state[i]:
			if _cell(cell).distance_to(p) < 60.0:
				return [i, cell]
	return []

func _select_seed(piece: int, cell: int) -> void:
	selected_piece = piece
	selected_seed = cell
	selected_pivot = int(state[piece][0]) if int(state[piece][1]) == cell else int(state[piece][1])
	choices = Puzzle.options(level, state, piece, selected_pivot)
	hint_move.clear()
	message_time = 0.0
	if cell in level.goals[piece]:
		choices.clear()
		blocked_cells = [cell]
		blocked_time = 0.8
		_notice("This seed has roots. Move its partner.")
	elif choices.is_empty():
		_explain_block(_cell(cell) + Vector2(0, 1))

func _drag(p: Vector2) -> void:
	gesture_end = p
	if not gesture_active or drag_piece < 0 or screen != "play" or not animation.is_empty():
		return
	if not dragging and gesture_start.distance_to(p) < 16.0:
		return
	dragging = true
	var pivot: Vector2 = _cell(selected_pivot)
	var from: Vector2 = _cell(drag_seed) - pivot
	drag_angle = clampf(from.angle_to(p - pivot), -PI * 0.5, PI * 0.5)
	drag_choice.clear()
	var nearest: float = PITCH * 0.75
	for choice: Dictionary in choices:
		var distance: float = _cell(int(choice.to)).distance_to(p)
		if distance < nearest and drag_angle * int(choice.turn) > 0.12:
			nearest = distance
			drag_choice = choice.duplicate()
	_publish()
	queue_redraw()

func _explain_block(p: Vector2) -> void:
	if selected_seed < 0:
		return
	var pivot: Vector2 = _cell(selected_pivot)
	var angle: float = (_cell(selected_seed) - pivot).angle_to(p - pivot)
	var turn: int = 1 if angle >= 0 else -1
	var info: Dictionary = Puzzle.explain(level, state, selected_piece, selected_seed, turn)
	blocked_cells = info.cells
	blocked_time = 0.9
	_notice(String(info.message))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		touch_id = -1
		_clear_gesture()
		if not level.is_empty():
			_save()
