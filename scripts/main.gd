extends Control

const Rules = preload("res://scripts/puzzle.gd")
const BG := Color("101725")
const PANEL := Color("192437")
const EMPTY := Color("222f43")
const TEXT := Color("f3efdf")
const MUTED := Color("8c9aae")
const MINT := Color("8ce5c5")
const CORAL := Color("eea579")
const GOLD := Color("ecd18a")
const COLORS := [MINT, CORAL, Color("a7b9f6")]
const BOARD := Vector2(102, 210)
const CELL := 86.0
const SAVE := "user://tessera.json"

var rules := Rules.new()
var levels: Array = []
var shapes: Array = []
var level_index := 0
var board: int = 0
var used := 0
var lines := 0
var selected := -1
var cursor := Vector2i(-1, -1)
var history: Array = []
var ink: Array[int] = []
var completed: Dictionary = {}
var clean: Dictionary = {}
var undos := 0
var hints := 0
var screen := "play"
var previous_screen := "play"
var font: Font
var bold: FontVariation
var buttons: Array = []
var hover := Vector2(-1,-1)
var press_origin := Vector2.ZERO
var piece_pressed := false
var dragging := false
var keyboard_cursor := false
var message := "Pick a piece. Then tap its top-left cell."
var message_time := 0.0
var flashes: Array = []
var clock := 0.0
var sound := true
var reduced_motion := false
var player: AudioStreamPlayer
var tones: Array[AudioStreamWAV] = []
var last_web_state := ""

func _ready() -> void:
	font = ThemeDB.fallback_font
	bold = FontVariation.new()
	bold.base_font = font
	bold.variation_embolden = 0.6
	levels = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	shapes = JSON.parse_string(FileAccess.get_file_as_string("res://data/shapes.json"))
	player = AudioStreamPlayer.new()
	add_child(player)
	for hz in [280.0, 560.0, 840.0]:
		tones.append(_make_tone(hz))
	_load_save()
	_load_level(level_index)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.tesseraReady=true;")
	print("TESSERA_READY levels=", levels.size())

func _make_tone(hz: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var count := 3300
	data.resize(count*2)
	for i in count:
		var t := float(i)/22050.0
		var envelope := sin(PI*float(i)/count)*exp(-t*24.0)
		var value := int(sin(TAU*hz*t)*envelope*3500.0)
		data.encode_s16(i*2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream

func _tone(index: int) -> void:
	if sound:
		player.stream = tones[index]
		player.play()

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if not data is Dictionary: return
	level_index = clampi(int(data.get("level", 0)), 0, levels.size()-1)
	if data.get("completed", {}) is Dictionary: completed = data.get("completed", {})
	if data.get("clean", {}) is Dictionary: clean = data.get("clean", {})
	sound = bool(data.get("sound", true))
	reduced_motion = bool(data.get("reduced_motion", false))

func _save() -> void:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"level":level_index,"completed":completed,
			"clean":clean,"sound":sound,"reduced_motion":reduced_motion}))

func _load_level(index: int) -> void:
	level_index = clampi(index, 0, levels.size()-1)
	rules.configure(levels[level_index], shapes)
	board = rules.initial
	used = 0
	lines = 0
	selected = -1
	cursor = Vector2i(-1,-1)
	ink.assign([])
	for _i in 36: ink.append(-1)
	history.clear()
	flashes.clear()
	undos = 0
	hints = 0
	piece_pressed = false
	dragging = false
	screen = "play"
	message = "Pick a piece. Then tap its top-left cell."
	message_time = 0
	_save()

func _scale() -> float:
	return minf(size.x/720.0, size.y/1000.0)

func _origin() -> Vector2:
	return (size-Vector2(720,1000)*_scale())*0.5

func _cell(point: Vector2) -> Vector2i:
	return Vector2i(floori((point.x-BOARD.x)/CELL), floori((point.y-BOARD.y)/CELL))

func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < 6 and cell.y < 6

func _select(index: int) -> void:
	if screen != "play" or not rules.available(used).has(index): return
	selected = index
	if keyboard_cursor:
		for option in rules.moves(board, used):
			if int(option.piece) == index:
				cursor = Vector2i(option.x, option.y)
				break

func _place(index: int, x: int, y: int) -> void:
	if screen != "play": return
	var next := rules.place(board, used, lines, index, x, y)
	if next.is_empty():
		_toast("That piece does not fit. Try another space.")
		return
	history.append({"board":board,"used":used,"lines":lines,"ink":ink.duplicate()})
	for i in 36:
		if int(next.added) & (1<<i): ink[i] = index%3
		if int(next.cleared) & (1<<i):
			flashes.append({"cell":i,"color":ink[i],"t":0.0})
			ink[i] = -1
	board = int(next.board)
	used = int(next.used)
	lines = int(next.total)
	selected = -1
	cursor = Vector2i(-1,-1)
	dragging = false
	piece_pressed = false
	if int(next.lines) > 0:
		_toast("Cross clear. +%d lines" % int(next.lines) if int(next.lines)>1 else "One line. More room.")
		_tone(1)
	else:
		_toast("Leave room for the next piece.")
		_tone(0)
	screen = rules.status(board, used, lines)
	if screen == "won":
		completed[str(level_index)] = true
		if undos == 0 and hints == 0: clean[str(level_index)] = true
		_save()
		_tone(2)

func _undo() -> void:
	if history.is_empty():
		_toast("No moves to undo.")
		return
	var state: Dictionary = history.pop_back()
	board = state.board
	used = state.used
	lines = state.lines
	ink.assign(state.ink)
	undos += 1
	selected = -1
	cursor = Vector2i(-1,-1)
	flashes.clear()
	screen = "play"
	_toast("One step back.")

func _hint() -> void:
	if screen != "play": return
	var route := rules.solve(board, used, lines, 12000)
	if route.is_empty():
		_toast("No quick route found. Try undoing a move.")
		return
	var action: Vector3i = route[0]
	if action.x < 0: return
	selected = action.x
	cursor = Vector2i(action.y, action.z)
	keyboard_cursor = true
	hints += 1
	_toast("Place this piece in the outlined space.")

func _toast(text: String) -> void:
	message = text
	message_time = 3.0

func _action(action: String) -> void:
	match action:
		"undo": _undo()
		"hint": _hint()
		"restart": _load_level(level_index)
		"next": _load_level(level_index+1) if level_index+1 < levels.size() else _open("levels")
		"levels", "help", "queue": _open(action)
		"close": screen = previous_screen
		"sound":
			sound = not sound
			_save()
		"motion":
			reduced_motion = not reduced_motion
			_save()
		_:
			if action.begins_with("level:"): _load_level(int(action.get_slice(":",1)))

func _open(name: String) -> void:
	previous_screen = screen
	screen = name

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = (event.position-_origin())/_scale()
		keyboard_cursor = false
		if selected >= 0 and screen == "play": cursor = _cell(hover)
		if piece_pressed and hover.distance_to(press_origin)>10:
			dragging = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = (event.position-_origin())/_scale()
		if not event.pressed:
			if dragging and selected >= 0 and _inside(_cell(point)):
				var cell := _cell(point)
				_place(selected, cell.x, cell.y)
			piece_pressed = false
			dragging = false
			return
		for button in buttons:
			if button.rect.has_point(point):
				_action(button.action)
				accept_event()
				return
		if screen != "play": return
		var group := rules.available(used)
		if not group.is_empty():
			var start: int = (group[0]/3)*3
			for slot in 3:
				if Rect2(48+slot*212, 779, 200, 116).has_point(point):
					_select(start+slot)
					piece_pressed = selected == start+slot
					press_origin = point
					accept_event()
					return
		var cell := _cell(point)
		if selected >= 0 and _inside(cell):
			_place(selected, cell.x, cell.y)
			accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	keyboard_cursor = true
	match event.keycode:
		KEY_1, KEY_2, KEY_3:
			var group := rules.available(used)
			if not group.is_empty(): _select((group[0]/3)*3+event.keycode-KEY_1)
		KEY_U, KEY_Z: _undo()
		KEY_H: _hint()
		KEY_R: _load_level(level_index)
		KEY_ESCAPE:
			if screen in ["help","levels","queue"]: screen = previous_screen
			else: selected = -1
		KEY_ENTER, KEY_SPACE:
			if screen == "won": _action("next")
			elif selected >= 0 and screen == "play": _place(selected,cursor.x,cursor.y)
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			if selected >= 0 and screen == "play":
				if not _inside(cursor): cursor = Vector2i.ZERO
				if event.keycode == KEY_LEFT: cursor.x = maxi(0,cursor.x-1)
				if event.keycode == KEY_RIGHT: cursor.x = mini(5,cursor.x+1)
				if event.keycode == KEY_UP: cursor.y = maxi(0,cursor.y-1)
				if event.keycode == KEY_DOWN: cursor.y = mini(5,cursor.y+1)
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	clock += delta
	message_time = maxf(0,message_time-delta)
	for flash in flashes: flash.t += delta
	flashes = flashes.filter(func(f): return f.t < 0.45)
	_sync_web()
	queue_redraw()

func _sync_web() -> void:
	if not OS.has_feature("web"): return
	var data := JSON.stringify({"game":"tessera","level":level_index+1,"board":str(board),
		"used":used,"lines":lines,"goal":rules.goal,"screen":screen,"selected":selected,
		"undos":undos,"hints":hints})
	if data == last_web_state: return
	last_web_state = data
	JavaScriptBridge.eval("(()=>{const s="+data+";const e=document.getElementById('game-state');if(e){for(const k in s)e.dataset[k]=s[k];e.textContent='Tessera. Board '+s.level+'. '+s.lines+' of '+s.goal+' lines. '+s.screen;}})();")

func _box(rect: Rect2, color: Color, radius: int = 14, border: Color = Color.TRANSPARENT, width: int = 1) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.set_border_width_all(width)
	draw_style_box(style,rect)

func _text(text: String, point: Vector2, px: int, color: Color = TEXT, strong: bool = false) -> void:
	draw_string(bold if strong else font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)

func _center(text: String, x: float, y: float, px: int, color: Color = TEXT, strong: bool = false) -> void:
	var f: Font = bold if strong else font
	_text(text,Vector2(x-f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x/2,y),px,color,strong)

func _button(rect: Rect2, label: String, action: String, filled: bool = false) -> void:
	var color := MINT if filled else PANEL
	if rect.has_point(hover): color = color.lightened(.08)
	_box(rect,color,12)
	_center(label,rect.get_center().x,rect.get_center().y+7,19,BG if filled else TEXT,filled)
	buttons.append({"rect":rect,"action":action})

func _tile(rect: Rect2, color: Color, alpha: float = 1.0) -> void:
	_box(rect,Color(color.darkened(.25),alpha),9)
	_box(Rect2(rect.position,rect.size-Vector2(0,4)),Color(color,alpha),9)
	draw_line(rect.position+Vector2(12,6),rect.position+Vector2(rect.size.x-12,6),Color(1,1,1,.18*alpha),2,true)

func _mini(shape: Array, center: Vector2, unit: float, color: Color, alpha: float = 1.0) -> void:
	var extent := Vector2.ZERO
	for p in shape: extent = extent.max(Vector2(float(p[0])+1,float(p[1])+1))
	var origin := center-extent*unit*.5
	for p in shape:
		_tile(Rect2(origin+Vector2(p[0],p[1])*unit+Vector2(2,2),Vector2.ONE*(unit-4)),color,alpha)

func _draw() -> void:
	if levels.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),BG)
	draw_set_transform(_origin(),0,Vector2.ONE*_scale())
	buttons.clear()
	_text("TESSERA",Vector2(48,76),38,TEXT,true)
	_text("MAKE ROOM. MAKE A LINE.",Vector2(50,103),12,MUTED)
	_button(Rect2(411,43,100,46),"Boards","levels")
	_button(Rect2(523,43,94,46),"Queue","queue")
	_button(Rect2(629,43,44,46),"?","help")
	_text("BOARD %02d   /   %s" % [level_index+1, str(levels[level_index].chapter).to_upper()],Vector2(50,148),12,MUTED,true)
	_text(str(levels[level_index].name),Vector2(48,184),27,TEXT,true)
	_text("%d / %d" % [lines,rules.goal],Vector2(551,157),29,MINT,true)
	_text("LINES",Vector2(559,180),11,MUTED)
	_draw_board()
	var note := message if message_time>0 else ("Choose a piece, then its top-left cell." if selected<0 else "Tap a cell to place. Dragging works too.")
	_center(note,360,757,17,MINT if message_time>0 else MUTED)
	_draw_hand()
	_button(Rect2(48,918,192,48),"Undo","undo")
	_button(Rect2(264,918,192,48),"Hint","hint")
	_button(Rect2(480,918,192,48),"Restart","restart")
	_center("No timer. Every placement counts.",360,989,12,MUTED)
	if screen != "play":
		buttons.clear()
		draw_rect(Rect2(0,0,720,1000),Color(.02,.04,.08,.80))
		match screen:
			"won","lost": _draw_result()
			"help": _draw_help()
			"levels": _draw_levels()
			"queue": _draw_queue()

func _draw_board() -> void:
	_box(Rect2(90,198,540,540),PANEL,22)
	for i in 36:
		var pos := BOARD+Vector2(i%6,i/6)*CELL
		var rect := Rect2(pos+Vector2(3,3),Vector2.ONE*(CELL-6))
		_box(rect,EMPTY,10)
		if board & (1<<i):
			_tile(rect,Color("647b99") if ink[i]<0 else COLORS[ink[i]])
		else:
			draw_circle(pos+Vector2.ONE*CELL*.5,2,Color("34465d"),true,-1,true)
	if selected >= 0 and _inside(cursor) and screen == "play":
		var preview := rules.place(board,used,lines,selected,cursor.x,cursor.y)
		var valid := not preview.is_empty()
		var color: Color = COLORS[selected%3] if valid else Color("ee7c7c")
		for p in shapes[int(rules.pieces[selected])]:
			var cell := cursor+Vector2i(int(p[0]),int(p[1]))
			if _inside(cell):
				var rect := Rect2(BOARD+Vector2(cell)*CELL+Vector2(4,4),Vector2.ONE*(CELL-8))
				_box(rect,Color(color,.24),9,color,2)
		if valid and int(preview.lines)>0:
			for i in 36:
				if int(preview.cleared)&(1<<i):
					_box(Rect2(BOARD+Vector2(i%6,i/6)*CELL+Vector2(3,3),Vector2.ONE*(CELL-6)),Color(MINT,.10),10,MINT,2)
	for flash in flashes:
		if reduced_motion: continue
		var i: int = flash.cell
		var rect := Rect2(BOARD+Vector2(i%6,i/6)*CELL+Vector2(3,3),Vector2.ONE*(CELL-6))
		_box(rect.grow(float(flash.t)*10),Color(MINT,(1.0-float(flash.t)/.45)*.7),10)

func _draw_hand() -> void:
	var group := rules.available(used)
	var start: int = (group[0]/3)*3 if not group.is_empty() else 0
	for slot in 3:
		var id := start+slot
		var rect := Rect2(48+slot*212,779,200,116)
		var active := group.has(id)
		_box(rect,PANEL if active else Color("141e2e"),16,COLORS[slot] if id==selected else Color.TRANSPARENT,2)
		if active:
			_mini(shapes[int(rules.pieces[id])],rect.get_center()+Vector2(0,4),25,COLORS[slot])
			_text(str(slot+1),rect.position+Vector2(13,23),12,MUTED)
		else:
			_center("Placed",rect.get_center().x,rect.get_center().y+5,14,MUTED)

func _draw_result() -> void:
	_box(Rect2(64,290,592,430),PANEL,24)
	var won := screen == "won"
	_center("BOARD %02d" % (level_index+1),360,337,13,MUTED,true)
	_center("Room for more." if won else "Out of room.",360,396,36,TEXT,true)
	_center("%d of %d lines cleared" % [lines,rules.goal],360,439,21,MINT if won else CORAL)
	var subtitle := "Solved without hints or undo." if hints==0 and undos==0 else "%d undos   /   %d hints" % [undos,hints]
	if not won: subtitle = "Try a different order or placement."
	_center(subtitle,360,478,17,MUTED)
	if won:
		_button(Rect2(104,523,512,60),"Next board" if level_index<levels.size()-1 else "All boards","next",true)
	else:
		_button(Rect2(104,523,512,60),"Undo last placement","undo",true)
	_button(Rect2(104,604,512,52),"Try this board again","restart")

func _draw_help() -> void:
	_box(Rect2(48,160,624,690),PANEL,24)
	_text("A little foresight.",Vector2(84,222),33,TEXT,true)
	var tips := [["01  Pick a piece","Choose one of the three pieces below the board."],
		["02  Find its space","Tap its top-left cell, or drag it onto the grid."],
		["03  Make a line","Full rows and columns clear together."],
		["04  Reach the target","Use the fixed pieces to clear enough lines."]]
	for i in tips.size():
		var y := 284+i*87
		_text(tips[i][0],Vector2(85,y),22,MINT,true)
		_text(tips[i][1],Vector2(85,y+30),17,MUTED)
	_center("Pieces stay upright. Queue shows what comes next.",360,636,16,MUTED)
	_center("1–3 choose · Arrows move · Enter places",360,674,16,MUTED)
	_center("U undo · H hint · R restart",360,700,16,MUTED)
	_button(Rect2(84,728,168,44),"Sound: on" if sound else "Sound: off","sound")
	_button(Rect2(264,728,168,44),"Less motion" if not reduced_motion else "Full motion","motion")
	_button(Rect2(444,728,192,44),"Let’s play","close",true)
	_center("Plan your order. Make space for the big pieces.",360,813,16,MUTED)

func _draw_levels() -> void:
	_box(Rect2(64,218,592,580),PANEL,24)
	_text("The collection",Vector2(104,278),34,TEXT,true)
	_text("%d / 18 complete" % completed.size(),Vector2(105,315),19,MUTED)
	for i in 18:
		var rect := Rect2(104+(i%6)*88,353+(i/6)*89,72,66)
		_button(rect,"%02d"%(i+1),"level:%d"%i,i==level_index)
		if completed.has(str(i)): draw_circle(rect.position+Vector2(59,12),4,MINT,clean.has(str(i)),1.5,true)
	_center("01–06 Learn   /   07–12 Plan   /   13–18 Master",360,657,16,MUTED)
	_button(Rect2(104,700,512,55),"Back to the board","close",true)

func _draw_queue() -> void:
	_box(Rect2(64,170,592,650),PANEL,24)
	_text("See the whole plan.",Vector2(104,231),32,TEXT,true)
	_text("Use each set of three before the next arrives.",Vector2(105,270),17,MUTED)
	for i in rules.pieces.size():
		var pos := Vector2(197+(i%3)*163,360+(i/3)*123)
		if i%3==0: _text("SET %d"%(i/3+1),Vector2(104,pos.y-49),12,MUTED,true)
		_mini(shapes[int(rules.pieces[i])],pos,24,COLORS[i%3],.20 if used&(1<<i) else 1.0)
	_button(Rect2(104,729,512,55),"Back to the board","close",true)
