extends Control

const Geometry = preload("res://scripts/geometry.gd")
const BG := Color("100e1c")
const INK := Color("f6f1ee")
const MUTED := Color("aaa1bc")
const BLUE := Color("aaa0ff")
const CORAL := Color("ff947f")
const GREEN := Color("a3f0cb")
const SAVE := "user://filament.json"
var levels: Array = []
var points: Array[Vector2] = []
var edges: Array = []
var anchors: Array = []
var report: Dictionary = {}
var history: Array = []
var completed: Dictionary = {}
var best: Dictionary = {}
var level_index := 0
var moves := 0
var hints := 0
var focus := -1
var dragging := -1
var pointer_id := -99
var drag_offset := Vector2.ZERO
var before_drag: Array[Vector2] = []
var screen := "play"
var previous_screen := "play"
var clock := 0.0
var entry := 0.0
var won_time := 0.0
var hint_node := -1
var hint_point := Vector2.ZERO
var hint_time := 0.0
var notice := ""
var notice_time := 0.0
var pulses: Array = []
var buttons: Array = []
var sound := true
var reduced_motion := false
var font: Font
var bold: FontVariation
var audio: AudioStreamPlayer
var tones: Array[AudioStreamWAV] = []
var last_web_state := ""
var keyboard_drag := false

func _ready() -> void:
	font = ThemeDB.fallback_font
	bold = FontVariation.new()
	bold.base_font = font
	bold.variation_embolden = 0.7
	levels = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	audio = AudioStreamPlayer.new()
	add_child(audio)
	for hz in [261.63,329.63,392.0,523.25]: tones.append(_make_tone(hz))
	_load_save()
	_load_level(level_index)
	if OS.has_feature("web"): JavaScriptBridge.eval("window.filamentReady=true;")
	print("FILAMENT_READY levels=",levels.size())

func _make_tone(hz: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(11025*2)
	for i in 11025:
		var t := float(i)/22050.0
		var envelope := minf(t*100.0,1.0)*exp(-t*10.0)
		var value := int((sin(TAU*hz*t)+0.24*sin(TAU*hz*2*t))*envelope*4200)
		data.encode_s16(i*2,value)
	var stream := AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=22050; stream.data=data
	return stream

func _tone(index: int) -> void:
	if sound:
		audio.stream=tones[index%tones.size()];audio.play()

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if not data is Dictionary: return
	level_index=clampi(int(data.get("level",0)),0,levels.size()-1)
	if data.get("completed") is Dictionary: completed=data.completed
	if data.get("best") is Dictionary: best=data.best
	sound=bool(data.get("sound",true))
	reduced_motion=bool(data.get("reduced_motion",false))

func _save() -> void:
	var file := FileAccess.open(SAVE,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"level":level_index,"completed":completed,"best":best,"sound":sound,"reduced_motion":reduced_motion}))

func _load_level(index: int) -> void:
	level_index=clampi(index,0,levels.size()-1)
	points.clear()
	for p in levels[level_index].points: points.append(Vector2(p[0],p[1]))
	edges=[]
	for e in levels[level_index].edges: edges.append([int(e[0]),int(e[1])])
	anchors=levels[level_index].anchors.map(func(a): return int(a))
	history.clear();pulses.clear();moves=0;hints=0;focus=-1;dragging=-1;pointer_id=-99
	keyboard_drag=false;screen="play";hint_node=-1;hint_time=0;notice_time=0;entry=0;won_time=0
	report=Geometry.inspect(points,edges)
	_save();_sync_web();queue_redraw()

func _scale() -> float:
	return minf(size.x/720.0,size.y/1000.0)

func _origin() -> Vector2:
	return (size-Vector2(720,1000)*_scale())/2.0

func _local(p: Vector2) -> Vector2:
	return (p-_origin())/_scale()

func _process(delta: float) -> void:
	clock+=delta;entry=minf(1.0,entry+delta*2.4)
	if screen=="won": won_time+=delta
	notice_time=maxf(0.0,notice_time-delta);hint_time=maxf(0.0,hint_time-delta)
	for pulse in pulses: pulse.age+=delta
	pulses=pulses.filter(func(p): return p.age<0.85)
	queue_redraw()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and dragging>=0:
		_cancel_drag()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed: _press(_local(event.position),event.index)
		elif pointer_id==event.index: _release()
	elif event is InputEventScreenDrag and pointer_id==event.index:
		_move(_local(event.position))
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==InputEvent.DEVICE_ID_EMULATION: return
		if event.pressed: _press(_local(event.position),-1)
		elif pointer_id==-1: _release()
	elif event is InputEventMouseMotion and pointer_id==-1:
		_move(_local(event.position))
	elif event is InputEventKey and event.pressed:
		_key(event)

func _press(p: Vector2, id: int) -> void:
	if dragging>=0: return
	for b in buttons:
		if b.rect.has_point(p): _action(b.action);return
	if screen!="play": return
	var closest := 43.0
	var candidates: Array[int] = []
	for i in points.size():
		var distance := p.distance_to(points[i])
		if distance<closest-0.01:
			closest=distance;candidates=[i]
		elif absf(distance-closest)<0.01: candidates.append(i)
	if candidates.is_empty(): return
	# Repeated touches cycle coincident knots, so none can become unreachable.
	var previous := candidates.find(focus)
	var chosen: int = candidates[(previous+1)%candidates.size()] if previous>=0 else candidates[-1]
	focus=chosen
	if chosen in anchors:
		_notice("This square knot is anchored.");_pulse(points[chosen],CORAL);_sync_web();return
	dragging=chosen;pointer_id=id;drag_offset=points[chosen]-p
	before_drag=points.duplicate();hint_time=0;keyboard_drag=false
	_pulse(points[chosen],BLUE);_tone(0);_sync_web()

func _move(p: Vector2) -> void:
	if dragging<0 or screen!="play": return
	var old: int = report.count
	points[dragging]=Geometry.clamp_point(p+drag_offset)
	report=Geometry.inspect(points,edges)
	if report.count<old:
		_pulse(points[dragging],GREEN)
	_sync_web()

func _release() -> void:
	if dragging<0: return
	var changed := points[dragging].distance_to(before_drag[dragging])>2.0
	if changed:
		history.append(before_drag.duplicate());moves+=1
		_tone(2 if report.count<Geometry.inspect(before_drag,edges).count else 1)
	else:
		points=before_drag.duplicate();report=Geometry.inspect(points,edges)
	dragging=-1;pointer_id=-99;keyboard_drag=false
	if changed and report.count==0: _win()
	_sync_web()

func _cancel_drag() -> void:
	if dragging<0: return
	points=before_drag.duplicate();report=Geometry.inspect(points,edges)
	dragging=-1;pointer_id=-99;keyboard_drag=false;_sync_web()

func _win() -> void:
	screen="won";won_time=0;hint_time=0;focus=-1
	completed[str(level_index)]=true
	if hints==0: best[str(level_index)]=mini(moves,int(best.get(str(level_index),9999)))
	for p in points: _pulse(p,GREEN)
	_tone(3);_save()

func _undo() -> void:
	_cancel_drag()
	if history.is_empty(): _notice("Nothing to undo yet.");return
	points=history.pop_back();moves=maxi(0,moves-1);screen="play";focus=-1;hint_time=0
	report=Geometry.inspect(points,edges);_sync_web();_tone(0)

func _hint() -> void:
	if screen!="play" or dragging>=0: return
	var best_count: int = report.count
	var chosen := -1
	var destination := Vector2.ZERO
	# Prefer an actual improvement from the current web. If locally stuck, a
	# witness position offers a way toward a known valid embedding.
	for i in points.size():
		if i in anchors: continue
		var candidates: Array[Vector2] = []
		var target: Array = levels[level_index].solution[i]
		candidates.append(Vector2(target[0],target[1]))
		for y in 5:
			for x in 6: candidates.append(Vector2(90+x*108,300+y*108))
		for p in candidates:
			var trial: Array[Vector2] = points.duplicate();trial[i]=p
			var value: int = Geometry.inspect(trial,edges).count
			if value<best_count: best_count=value;chosen=i;destination=p
	if chosen<0:
		var farthest := 0.0
		for i in points.size():
			if i in anchors: continue
			var p := Vector2(levels[level_index].solution[i][0],levels[level_index].solution[i][1])
			if points[i].distance_to(p)>farthest:
				farthest=points[i].distance_to(p);chosen=i;destination=p
	if chosen>=0:
		hint_node=chosen;hint_point=destination;hint_time=12.0;hints+=1
		_notice("Try moving the ringed knot to the dotted circle.")
	_sync_web()

func _action(action: String) -> void:
	_cancel_drag()
	if action.begins_with("level:"):
		_load_level(int(action.get_slice(":",1)));return
	match action:
		"undo": _undo()
		"reset": _load_level(level_index)
		"hint": _hint()
		"next": _load_level((level_index+1)%levels.size())
		"levels", "help":
			previous_screen=screen;screen=action
		"close": screen=previous_screen
		"sound": sound=not sound;_save()
		"motion": reduced_motion=not reduced_motion;_save()
	_sync_web()

func _key(event: InputEventKey) -> void:
	if event.keycode==KEY_ESCAPE:
		if dragging>=0: _cancel_drag()
		elif screen in ["help","levels"]: _action("close")
		return
	if event.echo and event.keycode not in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: return
	if event.keycode==KEY_TAB and screen=="play":
		if dragging>=0: _release()
		focus=posmod(focus+(-1 if event.shift_pressed else 1),points.size())
		_sync_web();get_viewport().set_input_as_handled();return
	if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN] and screen=="play" and focus>=0:
		if focus in anchors: _notice("This square knot is anchored.");return
		if dragging<0:
			dragging=focus;before_drag=points.duplicate();keyboard_drag=true;drag_offset=Vector2.ZERO
		var step := 5.0 if event.shift_pressed else 20.0
		var direction := Vector2.ZERO
		match event.keycode:
			KEY_LEFT: direction.x=-step
			KEY_RIGHT: direction.x=step
			KEY_UP: direction.y=-step
			KEY_DOWN: direction.y=step
		_move(points[focus]+direction);return
	if event.keycode in [KEY_ENTER,KEY_SPACE]:
		if screen=="won": _action("next")
		elif dragging>=0: _release()
		return
	if event.keycode==KEY_U and screen in ["play","won"]: _undo()
	elif event.keycode==KEY_R and screen in ["play","won"]: _action("reset")
	elif event.keycode==KEY_H and screen=="play": _hint()
	elif event.keycode==KEY_L and screen in ["play","won"]: _action("levels")

func _notice(value: String) -> void:
	notice=value;notice_time=4.5

func _pulse(p: Vector2, color: Color) -> void:
	if pulses.size()<48: pulses.append({"p":p,"color":color,"age":0.0})

func _text(value: String, p: Vector2, pixels: int, color: Color=INK, weight: bool=false) -> void:
	draw_string(bold if weight else font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _center(value: String, y: float, pixels: int, color: Color=INK) -> void:
	_text(value,Vector2(360-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x/2.0,y),pixels,color)

func _pill(rect: Rect2, fill: Color, outline: Color=Color.TRANSPARENT) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color=fill;style.corner_radius_top_left=24;style.corner_radius_top_right=24
	style.corner_radius_bottom_left=24;style.corner_radius_bottom_right=24
	if outline.a>0: style.set_border_width_all(1);style.border_color=outline
	draw_style_box(style,rect)

func _button(rect: Rect2, label: String, action: String, filled: bool=false) -> void:
	_pill(rect,GREEN if filled else Color("211c31"),Color.TRANSPARENT if filled else Color("42364f"))
	var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,25).x
	_text(label,rect.position+Vector2((rect.size.x-width)/2.0,rect.size.y/2.0+9),25,BG if filled else INK)
	buttons.append({"rect":rect,"action":action})

func _glow(p: Vector2, radius: float, color: Color) -> void:
	for i in range(5,0,-1):
		draw_circle(p,radius+i*7,Color(color,0.018*float(6-i)),true,-1,true)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),BG)
	draw_set_transform(_origin(),0,Vector2.ONE*_scale())
	buttons.clear()
	if levels.is_empty(): return
	var t := 0.0 if reduced_motion else clock
	# A quiet luminous field; no grid, slots, inventory or board frame.
	for i in range(15,0,-1):
		draw_circle(Vector2(360+sin(t*0.09)*35,515),float(i)*25,Color(0.20,0.11,0.37,0.018),true,-1,true)
	for i in 36:
		var p := Vector2(48+fmod(i*149.0,624),252+fmod(i*83.0,520))
		draw_circle(p,1.1,Color(BLUE,0.10+0.07*sin(t*0.6+i)),true,-1,true)
	_text("F I L A M E N T",Vector2(42,61),24,INK,true)
	_button(Rect2(489,26,99,52),"Webs","levels")
	_button(Rect2(604,26,74,52),"?","help")
	if screen=="levels": _draw_levels();return
	if screen=="help": _draw_help();return
	_text("%02d / %02d   ·   %s" % [level_index+1,levels.size(),"UNTANGLED" if screen=="won" else "UNTANGLE THE WEB"],Vector2(44,126),19,GREEN if screen=="won" else MUTED)
	_text("Beautifully done." if screen=="won" else str(levels[level_index].name),Vector2(42,187),45,INK,true)
	_text("A little space. A little clarity." if screen=="won" else "Drag the knots. Uncross every strand.",Vector2(44,225),25,MUTED)
	_pill(Rect2(537,119,141,91),Color("251e32"))
	var count_label := str(report.count)
	_text(count_label,Vector2(607-bold.get_string_size(count_label,HORIZONTAL_ALIGNMENT_LEFT,-1,40).x/2,163),40,GREEN if report.count==0 else CORAL,true)
	_text("tangles",Vector2(567,192),20,MUTED)
	_draw_web(t)
	if screen=="won":
		_center("%d moves  ·  %s" % [moves,"No hints" if hints==0 else "%d hints" % hints],820,26,GREEN)
		_button(Rect2(235,860,250,66),"Next web" if level_index<levels.size()-1 else "Play again","next",true)
		_center("All twelve webs complete." if completed.size()==levels.size() else "Let it breathe.",964,22,MUTED)
	else:
		var subtitle := str(levels[level_index].note)
		if notice_time>0: subtitle=notice
		elif dragging>=0: subtitle="Release to settle." if report.count==0 else "Keep pulling. You can cross strands while moving."
		elif report.nodes.size()>0: subtitle="Give the knots and strands a little more space."
		_center(subtitle,817,23,GREEN if report.count==0 else MUTED)
		_button(Rect2(117,864,146,60),"Undo","undo")
		_button(Rect2(287,864,146,60),"Hint","hint")
		_button(Rect2(457,864,146,60),"Reset","reset")
		_center("%d %s" % [moves,"move" if moves==1 else "moves"],965,22,MUTED)

func _draw_web(t: float) -> void:
	for i in edges.size():
		var e: Array = edges[i]
		var a := points[e[0]]
		var b := points[e[1]]
		var color := GREEN if screen=="won" else (CORAL if report.edges.has(i) else BLUE)
		var opacity := 0.8 if dragging<0 or dragging in e else 0.30
		draw_line(a,b,Color(color,0.035*entry),19,true)
		draw_line(a,b,Color(color,0.09*entry),9,true)
		draw_line(a,b,Color(color,opacity*entry),3.0,true)
		if not reduced_motion:
			for n in 2:
				var phase := fposmod(t*(0.12 if screen!="won" else 0.28)+i*0.173+n*0.5,1.0)
				var p := a.lerp(b,phase)
				var tail := a.lerp(b,maxf(0.0,phase-0.055))
				draw_line(tail,p,Color(color,0.8*entry),4,true)
				draw_circle(p,2.5,Color(INK,0.8*entry),true,-1,true)
	# Small diamonds identify actual crossings independently of colour.
	for p in report.marks:
		draw_circle(p,7,BG,true,-1,true)
		var diamond := PackedVector2Array([p+Vector2(0,-4),p+Vector2(4,0),p+Vector2(0,4),p+Vector2(-4,0)])
		draw_colored_polygon(diamond,CORAL)
	if hint_time>0 and hint_node>=0:
		draw_dashed_line(points[hint_node],hint_point,Color(GREEN,0.6),2,8,true,true)
		draw_arc(hint_point,30,0,TAU,48,GREEN,2,true)
		draw_arc(points[hint_node],36,0,TAU,48,GREEN,2,true)
	for i in points.size():
		var p := points[i]
		var anchored := i in anchors
		var selected := dragging==i or focus==i
		var color := GREEN if screen=="won" else (CORAL if report.nodes.has(i) else BLUE)
		var radius := 22.0+(3.0 if dragging==i else 0.0)
		_glow(p,radius,color)
		if selected:
			draw_arc(p,radius+12,0,TAU,48,Color(INK,0.65),1.5,true)
		if anchored:
			var box := Rect2(p-Vector2(21,21),Vector2(42,42))
			draw_rect(box,Color("292039"));draw_rect(box,Color(INK,0.85),false,2)
			draw_circle(p,5,INK,true,-1,true)
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				draw_line(p+direction*26,p+direction*31,Color(INK,0.45),2,true)
		else:
			draw_circle(p,radius+2,Color(color,0.65),true,-1,true)
			draw_circle(p,radius,Color("282038"),true,-1,true)
			for j in range(5,0,-1):
				draw_circle(p-Vector2(2,3),j*3.3,Color(color,0.05+float(6-j)*0.022),true,-1,true)
			draw_circle(p,7.0+sin(t*1.8+i)*0.7,INK,true,-1,true)
			draw_arc(p,radius+7,0.2+t*0.4+i,1.3+t*0.4+i,18,Color(color,0.30),1.5,true)
		if focus==i:
			_text(str(i+1),p+Vector2(-7,-38),18,INK)
	if not reduced_motion:
		for pulse in pulses:
			var progress: float = pulse.age/0.85
			draw_arc(pulse.p,24+progress*58,0,TAU,48,Color(pulse.color,(1.0-progress)*0.45),2,true)
		if screen=="won" and won_time<2.2:
			for i in 32:
				var angle := i*2.39996
				var distance := won_time*(90+fmod(i*33.0,160))
				var p := Vector2(360,520)+Vector2.from_angle(angle)*distance
				draw_circle(p,2.5,Color(GREEN,maxf(0.0,1.0-won_time/2.2)),true,-1,true)

func _draw_levels() -> void:
	buttons.clear()
	_text("Choose a web.",Vector2(44,161),46,INK,true)
	_text("Twelve small tangles. Find your flow.",Vector2(46,205),25,MUTED)
	for i in levels.size():
		var column := i%2
		var row := i/2
		var rect := Rect2(42+column*326,245+row*95,310,79)
		_pill(rect,Color("211c31"),GREEN if completed.has(str(i)) else Color("42364f"))
		_text("%02d" % (i+1),rect.position+Vector2(17,48),26,GREEN if completed.has(str(i)) else BLUE)
		_text(str(levels[i].name),rect.position+Vector2(68,46),24,INK)
		buttons.append({"rect":rect,"action":"level:%d" % i})
	_button(Rect2(260,871,200,60),"Back","close")
	_center("%d of 12 untangled" % completed.size(),968,23,MUTED)

func _draw_help() -> void:
	buttons.clear()
	_text("Find your flow.",Vector2(44,162),46,INK,true)
	var lines := ["Drag a round knot to move it.","Uncross all strands to finish the web.","Coral diamonds mark crossings.","Keep knots away from other strands.","Square knots are fixed anchors.","There is no timer. Undo as often as you like."]
	for i in lines.size():
		draw_circle(Vector2(52,232+i*49),3,BLUE,true,-1,true)
		_text(lines[i],Vector2(72,241+i*49),25,INK)
	_text("KEYBOARD",Vector2(46,565),20,BLUE)
	_text("Tab: choose knot. Arrows: move. Enter: release.",Vector2(46,607),24,MUTED)
	_text("Shift: fine movement. Esc: cancel. U: undo.",Vector2(46,645),24,MUTED)
	_button(Rect2(46,704,302,60),"Sound: on" if sound else "Sound: off","sound")
	_button(Rect2(372,704,302,60),"Motion: calm" if reduced_motion else "Motion: full","motion")
	_button(Rect2(235,850,250,66),"Back to the web","close",true)

func _sync_web() -> void:
	if not OS.has_feature("web") or report.is_empty(): return
	var coords: Array = []
	for p in points: coords.append([snappedf(p.x,0.01),snappedf(p.y,0.01)])
	var state := {"game":"filament","level":level_index+1,"screen":screen,"tangles":report.count,"moves":moves,"hints":hints,"dragging":dragging,"focus":focus,"points":JSON.stringify(coords),"completed":completed.size(),"motion":"calm" if reduced_motion else "full","sound":"on" if sound else "off"}
	var packed := JSON.stringify(state)
	if packed==last_web_state: return
	last_web_state=packed
	JavaScriptBridge.eval("(()=>{const s="+packed+";const e=document.getElementById('game-state');for(const k in s)e.dataset[k]=s[k];e.textContent='Web '+s.level+'. '+s.tangles+' tangles. '+s.moves+' moves. '+s.screen;})();")
