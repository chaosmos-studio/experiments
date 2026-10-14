extends SceneTree
const Rules = preload("res://scripts/puzzle.gd")
var failures := 0
var assertions := 0

func check(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func follow(rules, route: Array, initial: int) -> Dictionary:
	var board := initial
	var used := 0
	var lines := 0
	for raw in route:
		var step := Vector3i(int(raw[0]),int(raw[1]),int(raw[2])) if raw is Array else Vector3i(raw)
		if step.x<0: break
		var next: Dictionary = rules.place(board,used,lines,step.x,step.y,step.z)
		check(not next.is_empty(),"Witness move is legal")
		if next.is_empty(): return {"board":board,"used":used,"lines":lines}
		check(int(next.board)&int(next.cleared)==0,"Cleared cells leave the board")
		board = next.board
		used = next.used
		lines = next.total
		if lines>=rules.goal: break
	return {"board":board,"used":used,"lines":lines}

func run() -> void:
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	var shapes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/shapes.json"))
	var rules := Rules.new()
	check(levels.size()==18,"Campaign has 18 boards")
	rules.configure(levels[0],shapes)
	var cross: int = 0
	for i in 6: cross |= (1<<i)|(1<<(i*6))
	var clear := rules.settle(cross)
	check(clear.lines==2 and clear.board==0 and clear.cleared==cross,"Cross clears row and column simultaneously")
	check(rules.shape_mask(shapes[0],-1,0)==0,"Negative anchor is invalid")
	check(rules.shape_mask(shapes[0],5,0)==0,"Shape cannot wrap at edge")
	check(rules.place(0,0,0,3,0,0).is_empty(),"Future set cannot be played early")
	check(rules.place(1,0,0,0,0,0).is_empty(),"Occupied cells reject placement")
	check(rules.available(3)==[2] and rules.available(7)==[3,4,5],"All three pieces are used before next set")
	check(rules.solve(rules.initial,0,0,0).is_empty() and rules.exhausted,"Limited search never invents a hint")
	var maximum := 0
	for level in levels:
		rules.configure(level,shapes)
		var state := follow(rules,level.solution,rules.initial)
		check(rules.status(state.board,state.used,state.lines)=="won","Every board has a winning witness")
		var route := rules.solve(rules.initial,0,0,15000)
		check(not route.is_empty(),"Independent runtime solver finds a route")
		maximum = maxi(maximum,rules.visits)
		state = follow(rules,route,rules.initial)
		check(state.lines>=rules.goal,"Solver route reaches target")
		state = follow(rules,level.failure_route,rules.initial)
		check(rules.status(state.board,state.used,state.lines)=="lost","Every board has a genuine losing route")
		check(state.lines<rules.goal,"Using pieces does not automatically win")
	# Controller and saved progress.
	var path := "user://tessera.json"
	var had_save := FileAccess.file_exists(path)
	var old_save := FileAccess.get_file_as_string(path) if had_save else ""
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"level":0,"sound":false,"reduced_motion":true}));file.close()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(not game.sound and game.reduced_motion,"Preferences load")
	var first: Array = levels[0].solution[0]
	game._select(int(first[0]))
	game._place(int(first[0]),int(first[1]),int(first[2]))
	check(game.history.size()==1 and game.used!=0,"Controller accepts placement")
	game._undo()
	check(game.board==int(levels[0].board) and game.used==0 and game.lines==0,"Undo restores board, hand and line count")
	check(game.undos==1,"Undo assistance is counted")
	game._hint()
	check(game.selected>=0 and game.hints==1,"Verified hint selects a piece and placement")
	game._action("queue")
	game._action("close")
	check(game.screen=="play" and game.hints==1,"Queue is free inspection")
	game._load_level(0)
	for action in levels[0].failure_route:
		game._place(int(action[0]),int(action[1]),int(action[2]))
	check(game.screen=="lost","Real scene detects loss")
	game._undo()
	check(game.screen=="play","Undo recovers from loss")
	game._load_level(0)
	for action in levels[0].solution:
		game._place(int(action[0]),int(action[1]),int(action[2]))
	check(game.screen=="won" and game.clean.has("0"),"Clean solution wins and is recorded")
	game._action("next")
	check(game.level_index==1 and game.used==0,"Next board starts clean")
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.level_index==1 and game.completed.has("0") and game.clean.has("0"),"Completion persists across reload")
	game.queue_free()
	await process_frame
	if had_save:
		file=FileAccess.open(path,FileAccess.WRITE);file.store_string(old_save);file.close()
	else: DirAccess.remove_absolute(path)
	print("TEST_RESULT assertions=%d failures=%d solver_max_nodes=%d" % [assertions,failures,maximum])
	quit(1 if failures else 0)
