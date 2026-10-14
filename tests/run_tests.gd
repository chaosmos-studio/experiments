extends SceneTree
const Geometry = preload("res://scripts/geometry.gd")
var assertions := 0
var failures := 0
func check(value: bool,label: String) -> void:
	assertions+=1
	if not value: failures+=1;push_error(label)
func _initialize() -> void:
	call_deferred("run")
func vectors(raw: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for p in raw: result.append(Vector2(p[0],p[1]))
	return result
func run() -> void:
	check(Geometry.intersects(Vector2(0,0),Vector2(10,10),Vector2(0,10),Vector2(10,0)),"Proper crossing")
	check(Geometry.intersects(Vector2(0,0),Vector2(10,0),Vector2(5,0),Vector2(15,0)),"Collinear overlaps cannot hide a crossing")
	check(not Geometry.intersects(Vector2(0,0),Vector2(10,0),Vector2(0,10),Vector2(10,10)),"Parallel separated strands")
	check(Geometry.intersects(Vector2(0,0),Vector2(10,0),Vector2(10,0),Vector2(10,10)),"Unrelated endpoints touching count")
	var pile: Array[Vector2] = [Vector2(300,400),Vector2(300,400),Vector2(300,400),Vector2(300,400)]
	check(Geometry.inspect(pile,[[0,1],[2,3]]).count>0,"Collapsed layout never wins")
	var on_line: Array[Vector2] = [Vector2(100,400),Vector2(500,400),Vector2(300,400)]
	check(Geometry.inspect(on_line,[[0,1]]).count>0,"A knot cannot hide on a strand")
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	check(levels.size()==12,"Twelve webs")
	for level in levels:
		var initial := vectors(level.points)
		var solved := vectors(level.solution)
		check(Geometry.inspect(initial,level.edges).count==int(level.initial_tangles),"Independent Python and Godot agree on initial tangles")
		check(Geometry.inspect(initial,level.edges).count>0,"Every level starts unsolved")
		check(Geometry.inspect(solved,level.edges).count==0,"Every solution passes Godot geometry")
		for a in level.anchors: check(initial[a]==solved[a],"Solution preserves anchors")
		for p in solved: check(Geometry.clamp_point(p)==p,"All solution coordinates reachable")
	var had_save := FileAccess.file_exists("user://filament.json")
	var old_save := FileAccess.get_file_as_string("user://filament.json") if had_save else ""
	var file := FileAccess.open("user://filament.json",FileAccess.WRITE)
	file.store_string('{"level":0,"sound":false,"reduced_motion":true}');file.close()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(not game.sound and game.reduced_motion,"Preferences load")
	check(game.light_mode,"Legacy saves adopt light mode")
	check(not game.music_enabled,"Legacy mute preference carries into music")
	check(not game.score.started,"No music autoplay before a gesture")
	check(game.score.bed.stream.loop and game.score.melody.stream.loop,"Both score stems loop")
	check(absf(game.score.bed.stream.get_length()-game.score.melody.stream.get_length())<0.001,"Score stems share one loop length")
	check(game.score.bed.stream.get_length()>50,"Full-length music is loaded")
	for index in levels.size():
		game._load_level(index)
		var first: Array[Vector2] = game.points.duplicate()
		if not game.anchors.is_empty():
			var anchor: int = game.anchors[0]
			game._press(game.points[anchor],0)
			game._move(Vector2(400,600));game._release()
			check(game.points==first and game.moves==0,"Anchors never move")
		var mobile := 0
		while mobile in game.anchors: mobile+=1
		game._press(game.points[mobile],0)
		game._press(game.points[(mobile+1)%game.points.size()],1)
		check(game.dragging==mobile and game.pointer_id==0,"Second finger cannot steal drag")
		game._move(Vector2(-400,2000))
		check(game.points[mobile]==Vector2(66,764),"Dragging clamps to playable space")
		game._cancel_drag()
		check(game.points==first and game.history.is_empty(),"Cancelled drag restores state without a move")
		game._press(game.points[mobile],-1);game._release()
		check(game.moves==0,"Tapping does not count as movement")
		game._press(game.points[mobile],-1);game._move(game.points[mobile]+Vector2(8,0));game._release()
		check(game.moves==1 and game.history.size()==1,"Drag is one transaction")
		game._undo()
		check(game.points==first and game.moves==0,"Undo precisely restores coordinates")
		game._hint()
		check(game.points==first and game.hint_node>=0 and game.hint_node not in game.anchors,"Hints guide without moving knots")
		var solved := vectors(levels[index].solution)
		for i in solved.size():
			if i in game.anchors or game.screen=="won": continue
			if game.points[i].distance_to(solved[i])<1: continue
			game._press(game.points[i],-1)
			if game.dragging!=i:
				game._release()
				game._press(game.points[i],-1)
			check(game.dragging==i,"Overlapping knots remain individually reachable")
			game._move(solved[i])
			check(game.screen=="play","Crossing zero during a drag does not prematurely win")
			game._release()
		check(game.screen=="won" and game.report.count==0,"Physical input route solves every level")
		check(game.completed.has(str(index)),"Completion saved")
	game._load_level(0)
	var tab := InputEventKey.new();tab.keycode=KEY_TAB;tab.pressed=true
	game._key(tab)
	check(game.focus==0,"Tab selects first knot")
	var right := InputEventKey.new();right.keycode=KEY_RIGHT;right.pressed=true
	var before: Vector2=game.points[0]
	game._key(right)
	check(game.points[0]==before+Vector2(20,0),"Keyboard moves selected knot")
	var escape := InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
	game._key(escape)
	check(game.points[0]==before and game.moves==0,"Escape cancels keyboard movement")
	game._key(right)
	var enter := InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true
	game._key(enter)
	check(game.moves==1 and game.dragging==-1,"Enter releases a keyboard move")
	game._action("settings")
	game._action("help");game._action("close")
	check(game.screen=="settings","Help returns to settings")
	game._action("sound");game._action("motion");game._action("theme")
	game._action("music")
	check(game.music_enabled and game.score.started,"Music starts from a gesture")
	await create_timer(0.35).timeout
	check(game.score.is_audible(),"Music plays after activation")
	var position: float = game.score.bed.get_playback_position()
	await create_timer(0.20).timeout
	check(game.score.bed.get_playback_position()>position,"Music playback advances")
	game._action("sound")
	check(not game.sound and game.score.is_audible(),"Effects mute does not stop music")
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.score.bed.stream_paused and game.score.melody.stream_paused,"Both music stems pause when unfocused")
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.score.is_audible(),"Music resumes after focus returns")
	game._action("music")
	await create_timer(0.7).timeout
	check(game.score.bed.stream_paused and game.score.melody.stream_paused,"Muted music fades then pauses both stems")
	game._action("sound")
	check(game.sound and not game.music_enabled,"Music mute is independent of effects")
	for i in 12: game._action("louder")
	check(game.music_volume==1.0,"Volume upper bound")
	for i in 14: game._action("quieter")
	check(game.music_volume==0.0,"Volume lower bound")
	for i in 4: game._action("louder")
	game._action("close")
	check(game.screen=="play" and game.sound and not game.reduced_motion,"Settings return to current web")
	check(not game.light_mode,"Dark mode is an explicit choice")
	# A portrait canvas uses more vertical room without changing puzzle geometry.
	game.size=Vector2(720,1440);await process_frame
	var original: Vector2 = game.points[0]
	check(game._world(game._graph(original)).distance_to(original)<0.001,"Portrait coordinates round-trip")
	game._press(game._graph(original),0)
	check(game.dragging==0,"Portrait touch selects the visible knot")
	game._move(game._world(game._graph(original+Vector2(20,10))));game._release()
	check(game.points[0].distance_to(original+Vector2(20,10))<0.01,"Portrait dragging follows the visible knot")
	game._undo()
	game.queue_free();await process_frame
	var reloaded=load("res://scenes/main.tscn").instantiate();root.add_child(reloaded);await process_frame
	check(reloaded.completed.size()==12 and reloaded.sound and not reloaded.reduced_motion,"Progress and preferences persist")
	check(not reloaded.light_mode and not reloaded.music_enabled and is_equal_approx(reloaded.music_volume,0.4),"Appearance, music and volume persist")
	check(not reloaded.score.started,"Reload does not autoplay saved music")
	reloaded._action("theme")
	check(reloaded.light_mode,"Light mode can be restored")
	reloaded.queue_free();await process_frame
	# Give the audio mixer a cycle to retire the stopped playback resources.
	await create_timer(0.15).timeout
	if had_save:
		file=FileAccess.open("user://filament.json",FileAccess.WRITE);file.store_string(old_save);file.close()
	else: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://filament.json"))
	print("FILAMENT_TESTS assertions=",assertions," failures=",failures)
	quit(0 if failures==0 else 1)
