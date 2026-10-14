extends Control

const Geometry = preload("res://scripts/geometry.gd")
const Score = preload("res://scripts/score.gd")
var BG := Color("f6f2eb")
var INK := Color("34313e")
var MUTED := Color("706b78")
var BLUE := Color("5965a2")
var CORAL := Color("b7634e")
var GREEN := Color("367760")
var PANEL := Color("fffcf7")
var BORDER := Color("e0d9ce")
var SHADOW := Color(0.26,0.21,0.30,0.055)
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
var light_mode := true
var music_enabled := true
var music_volume := 0.5
var score: Node
var display_font: FontVariation
var glow_texture: GradientTexture2D
var screen_stack: Array[String] = []
var hover := Vector2(-999,-999)
var last_layout := Vector2.ZERO
var last_audio_playing := false


func _ready() -> void:
	var source_font: Font = load("res://assets/fonts/Manrope.ttf")
	var weight_axis := TextServerManager.get_primary_interface().name_to_tag("wght")
	var body_font := FontVariation.new()
	body_font.base_font=source_font
	body_font.variation_opentype={weight_axis:500.0}
	font=body_font
	bold=FontVariation.new()
	bold.base_font=source_font
	bold.variation_opentype={weight_axis:650.0}
	display_font=FontVariation.new()
	display_font.base_font=load("res://assets/fonts/CormorantGaramond-Italic.ttf")
	display_font.variation_opentype={weight_axis:550.0}
	var gradient := Gradient.new()
	gradient.offsets=PackedFloat32Array([0.0,0.35,1.0])
	gradient.colors=PackedColorArray([Color(1,1,1,0.65),Color(1,1,1,0.20),Color(1,1,1,0)])
	glow_texture=GradientTexture2D.new()
	glow_texture.width=128;glow_texture.height=128
	glow_texture.fill=GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from=Vector2(0.5,0.5);glow_texture.fill_to=Vector2(1,0.5)
	glow_texture.gradient=gradient
	levels = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	audio = AudioStreamPlayer.new()
	add_child(audio)
	for hz in [293.66,369.99,440.0,587.33]: tones.append(_make_tone(hz))
	_load_save()
	_palette()
	score=Score.new();add_child(score)
	score.enabled=music_enabled;score.volume=music_volume
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
	light_mode=str(data.get("theme","light"))!="dark"
	music_enabled=bool(data.get("music",data.get("sound",true)))
	music_volume=clampf(float(data.get("music_volume",0.5)),0.0,1.0)

func _save() -> void:
	var file := FileAccess.open(SAVE,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"level":level_index,"completed":completed,"best":best,"sound":sound,"reduced_motion":reduced_motion,"theme":"light" if light_mode else "dark","music":music_enabled,"music_volume":music_volume}))

func _load_level(index: int) -> void:
	level_index=clampi(index,0,levels.size()-1)
	points.clear()
	for p in levels[level_index].points: points.append(Vector2(p[0],p[1]))
	edges=[]
	for e in levels[level_index].edges: edges.append([int(e[0]),int(e[1])])
	anchors=levels[level_index].anchors.map(func(a): return int(a))
	history.clear();pulses.clear();screen_stack.clear();moves=0;hints=0;focus=-1;dragging=-1;pointer_id=-99
	keyboard_drag=false;screen="play";hint_node=-1;hint_time=0;notice_time=0;entry=0;won_time=0
	report=Geometry.inspect(points,edges)
	_save();_sync_web();queue_redraw()

func _scale() -> float:
	return minf(size.x/720.0,size.y/1000.0)

func _origin() -> Vector2:
	return (size-Vector2(720,_height())*_scale())/2.0

func _local(p: Vector2) -> Vector2:
	return (p-_origin())/_scale()

func _height() -> float:
	return clampf(size.y/_scale(),1000.0,1440.0)

func _graph_scale() -> float:
	return 1.10 if _height()>1100 else 1.0

func _graph(p: Vector2) -> Vector2:
	return (p-Vector2(360,520))*_graph_scale()+Vector2(360,520+(_height()-1000)/2.0)

func _world(p: Vector2) -> Vector2:
	return (p-Vector2(360,520+(_height()-1000)/2.0))/_graph_scale()+Vector2(360,520)

func _palette() -> void:
	BG=Color("f6f2eb" if light_mode else "12111e")
	INK=Color("34313e" if light_mode else "f6f1ea")
	MUTED=Color("706b78" if light_mode else "aea6bc")
	BLUE=Color("5965a2" if light_mode else "aaa9ef")
	CORAL=Color("b7634e" if light_mode else "efa58d")
	GREEN=Color("367760" if light_mode else "a3ddc2")
	PANEL=Color("fffcf7" if light_mode else "211e2e")
	BORDER=Color("e0d9ce" if light_mode else "423c52")
	SHADOW=Color(0.26,0.21,0.30,0.055) if light_mode else Color(0,0,0,0.15)
	pulses.clear()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.theme='"+("light" if light_mode else "dark")+"';try{localStorage.setItem('filament-theme','"+("light" if light_mode else "dark")+"')}catch(e){}")

func _process(delta: float) -> void:
	clock+=delta;entry=minf(1.0,entry+delta*2.4)
	if screen=="won": won_time+=delta
	notice_time=maxf(0.0,notice_time-delta);hint_time=maxf(0.0,hint_time-delta)
	for pulse in pulses: pulse.age+=delta
	pulses=pulses.filter(func(p): return p.age<0.85)
	if score and not report.is_empty():
		score.clarity=1.0-clampf(float(report.count)/maxf(1.0,float(levels[level_index].initial_tangles)),0.0,1.0)
	if score and score.is_audible()!=last_audio_playing:
		last_audio_playing=score.is_audible()
		_sync_web()
	if size!=last_layout:
		last_layout=size
		_cancel_drag()
		_sync_web()
	queue_redraw()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancel_drag()
		if score: score.set_active(false)
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
		if score: score.set_active(true)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed: _press(_local(event.position),event.index)
		elif pointer_id==event.index: _release()
	elif event is InputEventScreenDrag and pointer_id==event.index:
		_move(_world(_local(event.position)))
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==InputEvent.DEVICE_ID_EMULATION: return
		if event.pressed: _press(_local(event.position),-1)
		elif pointer_id==-1: _release()
	elif event is InputEventMouseMotion:
		hover=_local(event.position)
		if pointer_id==-1: _move(_world(hover))
	elif event is InputEventKey and event.pressed:
		_key(event)

func _press(p: Vector2, id: int) -> void:
	if score: score.unlock()
	if dragging>=0: return
	for b in buttons:
		if b.rect.has_point(p): _action(b.action);return
	if screen!="play": return
	p=_world(p)
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
		"levels", "help", "settings":
			screen_stack.append(screen);screen=action
		"close": screen=screen_stack.pop_back() if not screen_stack.is_empty() else "play"
		"sound": sound=not sound;_save()
		"music":
			music_enabled=not music_enabled;score.enabled=music_enabled;score.unlock();_save()
			_notice("Music on." if music_enabled else "Music off.")
		"quieter", "louder":
			music_volume=clampf(snappedf(music_volume+(-0.1 if action=="quieter" else 0.1),0.1),0.0,1.0)
			score.volume=music_volume;score.unlock();_save()
		"motion": reduced_motion=not reduced_motion;_save()
		"theme": light_mode=not light_mode;_palette();_save()
	_sync_web()

func _key(event: InputEventKey) -> void:
	if score: score.unlock()
	if event.keycode==KEY_ESCAPE:
		if dragging>=0: _cancel_drag()
		elif screen in ["help","levels","settings"]: _action("close")
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
	if event.keycode==KEY_M: _action("music")
	elif event.keycode==KEY_U and screen in ["play","won"]: _undo()
	elif event.keycode==KEY_R and screen in ["play","won"]: _action("reset")
	elif event.keycode==KEY_H and screen=="play": _hint()
	elif event.keycode==KEY_L and screen in ["play","won"]: _action("levels")

func _notice(value: String) -> void:
	notice=value;notice_time=4.5

func _pulse(p: Vector2, color: Color) -> void:
	if pulses.size()<48: pulses.append({"p":p,"color":color,"age":0.0})

func _text(value: String, p: Vector2, pixels: int, color: Color=Color.TRANSPARENT, weight: bool=false) -> void:
	draw_string(bold if weight else font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,INK if color==Color.TRANSPARENT else color)

func _center(value: String, y: float, pixels: int, color: Color=Color.TRANSPARENT, face: Font=null) -> void:
	var chosen: Font = face if face else font
	var width := chosen.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x
	draw_string(chosen,Vector2(360-width/2,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,INK if color==Color.TRANSPARENT else color)

func _pill(rect: Rect2, fill: Color, outline: Color=Color.TRANSPARENT, radius: int=24) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color=fill;style.set_corner_radius_all(radius)
	if outline.a>0: style.set_border_width_all(1);style.border_color=outline
	draw_style_box(style,rect)

func _button(rect: Rect2, label: String, action: String, filled: bool=false) -> void:
	var over := rect.has_point(hover)
	_pill(rect,GREEN if filled else (PANEL.lerp(BLUE,0.06) if over else PANEL),Color.TRANSPARENT if filled else BORDER)
	var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,25).x
	_text(label,rect.position+Vector2((rect.size.x-width)/2,rect.size.y/2+9),25,BG if filled else INK)
	var padding := Vector2(maxf(0,84-rect.size.x),maxf(0,84-rect.size.y))/2
	buttons.append({"rect":Rect2(rect.position-padding,rect.size+padding*2),"action":action})

func _icon(kind: String, p: Vector2, color: Color) -> void:
	match kind:
		"music":
			for i in 4:
				var length: float = [6.0,14.0,10.0,18.0][i]
				if music_enabled and not reduced_motion: length+=sin(clock*2.0+i*1.7)*3
				draw_line(p+Vector2(-12+i*8,-length/2),p+Vector2(-12+i*8,length/2),color,3,true)
			if not music_enabled: draw_line(p+Vector2(-18,18),p+Vector2(18,-18),color,2,true)
		"settings":
			for i in 3:
				var y := -12.0+i*12
				draw_line(p+Vector2(-15,y),p+Vector2(15,y),color,2,true)
				var x := -7.0 if i%2==0 else 7.0
				draw_circle(p+Vector2(x,y),4,PANEL,true,-1,true)
				draw_arc(p+Vector2(x,y),4,0,TAU,20,color,2,true)
		"undo":
			draw_arc(p,13,-PI*0.85,PI*0.70,32,color,2,true)
			draw_polyline(PackedVector2Array([p+Vector2(-16,-1),p+Vector2(-11,-8),p+Vector2(-3,-6)]),color,2,true)
		"hint":
			draw_arc(p-Vector2(0,4),10,PI*0.8,PI*2.2,32,color,2,true)
			draw_line(p+Vector2(-6,2),p+Vector2(-5,10),color,2,true)
			draw_line(p+Vector2(6,2),p+Vector2(5,10),color,2,true)
			draw_line(p+Vector2(-5,10),p+Vector2(5,10),color,2,true)
			draw_line(p+Vector2(-3,15),p+Vector2(3,15),color,2,true)
		"reset":
			draw_arc(p,13,-PI*0.45,PI*1.25,32,color,2,true)
			draw_polyline(PackedVector2Array([p+Vector2(0,-17),p+Vector2(7,-12),p+Vector2(1,-6)]),color,2,true)
		"levels":
			for x in 2:
				for y in 2: _pill(Rect2(p+Vector2(-14+x*17,-14+y*17),Vector2(11,11)),Color.TRANSPARENT,color,3)

func _round_button(p: Vector2, kind: String) -> void:
	var rect := Rect2(p-Vector2(42,42),Vector2(84,84))
	if rect.has_point(hover): draw_circle(p,29,Color(BLUE,0.07),true,-1,true)
	_icon(kind,p,INK if kind!="music" or music_enabled else MUTED)
	buttons.append({"rect":rect,"action":kind})

func _glow(p: Vector2, radius: float, color: Color) -> void:
	draw_texture_rect(glow_texture,Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2),false,color)

func _header() -> void:
	var mark := PackedVector2Array([Vector2(44,38),Vector2(70,65),Vector2(70,38),Vector2(44,65)])
	draw_polyline(mark,BLUE,1.7,true)
	for p in mark: draw_circle(p,3.5,BLUE,true,-1,true)
	_text("F I L A M E N T",Vector2(91,61),22,INK,true)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),BG)
	draw_set_transform(_origin(),0,Vector2.ONE*_scale())
	buttons.clear()
	if levels.is_empty(): return
	var t := 0.0 if reduced_motion else clock
	var h := _height()
	_glow(Vector2(240+sin(t*0.08)*35,h*0.48),420,Color(BLUE,0.065 if light_mode else 0.08))
	_glow(Vector2(520,h*0.62),340,Color(CORAL,0.045))
	_header()
	if screen=="levels": _draw_levels();return
	if screen=="help": _draw_help();return
	if screen=="settings": _draw_settings();return
	_round_button(Vector2(548,52),"music")
	_round_button(Vector2(636,52),"settings")
	_center("W E B   %02d   /   %02d" % [level_index+1,levels.size()],114,18,MUTED)
	_center("Untangled." if screen=="won" else str(levels[level_index].name),177,64,INK,display_font)
	_center("A little space. A little clarity." if screen=="won" else "Drag the knots. Uncross every strand.",214,24,MUTED)
	_pill(Rect2(187,230,346,48),Color(PANEL,0.85),BORDER,26)
	var count_label := "%d %s" % [report.count,"tangle" if report.count==1 else "tangles"]
	_text(count_label,Vector2(211,262),22,GREEN if report.count==0 else CORAL,true)
	draw_line(Vector2(372,241),Vector2(372,265),BORDER,1,true)
	_text("%d %s" % [moves,"move" if moves==1 else "moves"],Vector2(396,262),22,MUTED)
	_draw_web(t)
	if screen=="won":
		var achievement := "Found your flow."
		if hints==0: achievement="Best: %d %s" % [int(best.get(str(level_index),moves)),"move" if int(best.get(str(level_index),moves))==1 else "moves"]
		_center(achievement,h-185,24,GREEN)
		_button(Rect2(117,h-135,178,78),"Replay","reset")
		_button(Rect2(313,h-135,290,78),"Next web" if level_index<levels.size()-1 else "Start again","next",true)
	else:
		var subtitle := str(levels[level_index].note)
		if notice_time>0: subtitle=notice
		elif dragging>=0: subtitle="Release to settle." if report.count==0 else "Give each strand a little room."
		elif report.nodes.size()>0: subtitle="Keep knots clear of other strands."
		_center(subtitle,h-185,23,GREEN if report.count==0 else MUTED)
		var actions := ["undo","hint","reset","levels"]
		var labels := ["Undo","Hint","Reset","Webs"]
		for i in 4:
			var rect := Rect2(42+i*162,h-136,150,86)
			_pill(rect,PANEL.lerp(BLUE,0.06) if rect.has_point(hover) else PANEL,BORDER,23)
			_icon(actions[i],rect.position+Vector2(75,28),MUTED if i==0 and history.is_empty() else INK)
			_text(labels[i],rect.position+Vector2((150-font.get_string_size(labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,20).x)/2,68),20,MUTED if i==0 and history.is_empty() else INK)
			buttons.append({"rect":rect,"action":actions[i]})
	_center("Room to Breathe" if music_enabled else "Take your time.",h-18,16,MUTED)

func _draw_web(t: float) -> void:
	for i in edges.size():
		var e: Array = edges[i]
		var a := _graph(points[e[0]])
		var b := _graph(points[e[1]])
		var color := GREEN if screen=="won" else (CORAL if report.edges.has(i) else BLUE)
		var opacity := 0.78 if dragging<0 or dragging in e else 0.28
		draw_line(a+Vector2(0,3),b+Vector2(0,3),SHADOW,5,true)
		draw_line(a,b,Color(color,0.06*entry),10,true)
		draw_line(a,b,Color(color,opacity*entry),3.0,true)
		if not reduced_motion:
			var phase := fposmod(t*(0.10 if screen!="won" else 0.22)+i*0.173,1.0)
			var p := a.lerp(b,phase)
			draw_line(a.lerp(b,maxf(0.0,phase-0.045)),p,Color(color,0.8*entry),4,true)
			draw_circle(p,2.3,Color(PANEL,entry),true,-1,true)
	for position in report.marks:
		var p := _graph(position)
		draw_circle(p,7,BG,true,-1,true)
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-4),p+Vector2(4,0),p+Vector2(0,4),p+Vector2(-4,0)]),CORAL)
	if hint_time>0 and hint_node>=0:
		draw_dashed_line(_graph(points[hint_node]),_graph(hint_point),Color(GREEN,0.6),2,8,true,true)
		draw_arc(_graph(hint_point),30,0,TAU,48,GREEN,2,true)
		draw_arc(_graph(points[hint_node]),36,0,TAU,48,GREEN,2,true)
	for i in points.size():
		var p := _graph(points[i])
		var anchored := i in anchors
		var selected := dragging==i or focus==i
		var color := GREEN if screen=="won" else (CORAL if report.nodes.has(i) else BLUE)
		var radius := 23.0+(3.0 if dragging==i else 0.0)
		_glow(p+Vector2(0,9),radius*2.3,Color(INK,0.12 if light_mode else 0.25))
		if selected:
			_glow(p,radius*3,Color(color,0.22))
			draw_arc(p,radius+10,0,TAU,48,Color(color,0.6),1.5,true)
		if anchored:
			_pill(Rect2(p-Vector2(21,21),Vector2(42,42)),PANEL,INK,8)
			draw_rect(Rect2(p-Vector2(4,4),Vector2(8,8)),INK)
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				draw_line(p+direction*26,p+direction*31,Color(INK,0.4),1.5,true)
		else:
			draw_circle(p,radius,PANEL,true,-1,true)
			draw_arc(p,radius,0,TAU,64,Color(color,0.65),1.6,true)
			draw_circle(p,radius-5,Color(color,0.08),true,-1,true)
			draw_circle(p,6.5+sin(t*1.8+i)*0.5,color,true,-1,true)
			draw_circle(p-Vector2(1.5,2),2.1,Color(PANEL,0.60),true,-1,true)
		if focus==i: _text(str(i+1),p+Vector2(-6,-39),16,INK)
	if not reduced_motion:
		for pulse in pulses:
			var progress: float = pulse.age/0.85
			draw_arc(_graph(pulse.p),25+progress*48,0,TAU,48,Color(pulse.color,(1-progress)*0.4),2,true)
		if screen=="won" and won_time<2.2:
			for i in 28:
				var p := _graph(Vector2(360,520))+Vector2.from_angle(i*2.39996)*won_time*(70+fmod(i*33.0,130))
				draw_circle(p,2.3,Color(GREEN,maxf(0,1-won_time/2.2)),true,-1,true)

func _draw_levels() -> void:
	var h := _height()
	_center("A little room to breathe.",165,53,INK,display_font)
	_center("%d of %d webs untangled" % [completed.size(),levels.size()],210,23,MUTED)
	var row_height := (h-340)/6.0
	for i in levels.size():
		var rect := Rect2(42+(i%2)*326,250+(i/2)*row_height,310,row_height-12)
		var done: bool = completed.has(str(i))
		_pill(rect,PANEL.lerp(BLUE,0.05) if rect.has_point(hover) else PANEL,GREEN if done else BORDER,20)
		var center := rect.position+Vector2(49,rect.size.y/2)
		for e in levels[i].edges:
			var a: Array = levels[i].solution[e[0]]
			var b: Array = levels[i].solution[e[1]]
			draw_line(center+(Vector2(a[0],a[1])-Vector2(360,520))*0.115,center+(Vector2(b[0],b[1])-Vector2(360,520))*0.115,Color(GREEN if done else BLUE,0.5),1.3,true)
		for raw in levels[i].solution:
			draw_circle(center+(Vector2(raw[0],raw[1])-Vector2(360,520))*0.115,2.5,GREEN if done else BLUE,true,-1,true)
		var y := rect.size.y/2
		_text("%02d  %s" % [i+1,"COMPLETE" if done else "UNTANGLE"],rect.position+Vector2(98,y-12),13,GREEN if done else MUTED,true)
		_text(str(levels[i].name),rect.position+Vector2(98,y+18),21,INK)
		buttons.append({"rect":rect,"action":"level:%d" % i})
	_button(Rect2(250,h-80,220,58),"Back","close")

func _setting_row(y: float, label: String, detail: String, value: String, action: String) -> void:
	_text(label,Vector2(72,y+30),26,INK,true)
	_text(detail,Vector2(72,y+64),19,MUTED)
	_button(Rect2(493,y+4,155,64),value,action)
	draw_line(Vector2(72,y+90),Vector2(648,y+90),BORDER,1,true)

func _draw_settings() -> void:
	var h := _height()
	_center("Make yourself at home.",169,56,INK,display_font)
	_center("Your pace. Your atmosphere.",211,23,MUTED)
	_pill(Rect2(42,251,636,584),PANEL,BORDER,28)
	_setting_row(274,"Music","Room to Breathe · original score","On" if music_enabled else "Off","music")
	_text("Volume",Vector2(72,424),23,INK)
	_button(Rect2(304,386,64,64),"−","quieter")
	_pill(Rect2(387,414,166,6),BORDER,Color.TRANSPARENT,3)
	if music_volume>0: _pill(Rect2(387,414,166*music_volume,6),BLUE,Color.TRANSPARENT,3)
	_text("%d%%" % roundi(music_volume*100),Vector2(450,449),16,MUTED)
	_button(Rect2(584,386,64,64),"+","louder")
	draw_line(Vector2(72,474),Vector2(648,474),BORDER,1,true)
	_setting_row(491,"Sound effects","Soft notes as you move","On" if sound else "Off","sound")
	_setting_row(598,"Appearance","A change of light","Light" if light_mode else "Dark","theme")
	_setting_row(705,"Motion","Settle the moving strands","Calm" if reduced_motion else "Full","motion")
	_button(Rect2(42,h-118,305,76),"How to play","help")
	_button(Rect2(373,h-118,305,76),"Back to the web","close",true)

func _draw_help() -> void:
	var h := _height()
	_center("Find your flow.",169,64,INK,display_font)
	_center("No timer. Just a little clarity.",211,24,MUTED)
	var lines := ["Drag a round knot to move it.","Uncross all strands to finish the web.","Coral diamonds mark crossings.","Keep knots away from other strands.","Square knots stay anchored.","Undo as often as you like."]
	for i in lines.size():
		draw_circle(Vector2(65,294+i*57),3,BLUE,true,-1,true)
		_text(lines[i],Vector2(86,303+i*57),24,INK)
	_pill(Rect2(42,647,636,166),PANEL,BORDER)
	_text("KEYBOARD",Vector2(68,685),16,BLUE,true)
	_text("Tab: choose knot. Arrows: move. Enter: release.",Vector2(68,725),22,MUTED)
	_text("Shift: fine movement. Esc: cancel. U: undo.",Vector2(68,762),22,MUTED)
	_text("M: music. H: hint. R: restart. L: webs.",Vector2(68,797),20,MUTED)
	_button(Rect2(235,h-118,250,76),"Back","close",true)

func _sync_web() -> void:
	if not OS.has_feature("web") or report.is_empty(): return
	var coords: Array = []
	for p in points: coords.append([snappedf(p.x,0.01),snappedf(p.y,0.01)])
	var state := {"game":"filament","level":level_index+1,"screen":screen,"tangles":report.count,"moves":moves,"hints":hints,"dragging":dragging,"focus":focus,"points":JSON.stringify(coords),"completed":completed.size(),"motion":"calm" if reduced_motion else "full","sound":"on" if sound else "off","theme":"light" if light_mode else "dark","music":"on" if music_enabled else "off","musicVolume":roundi(music_volume*100),"audioStarted":score.started if score else false,"audioPlaying":score.is_audible() if score else false,"layoutHeight":_height(),"graphScale":_graph_scale()}
	var packed := JSON.stringify(state)
	if packed==last_web_state: return
	last_web_state=packed
	JavaScriptBridge.eval("(()=>{const s="+packed+";const e=document.getElementById('game-state');for(const k in s)e.dataset[k]=s[k];e.textContent='Web '+s.level+'. '+s.tangles+' tangles. '+s.moves+' moves. '+s.screen;})();")
