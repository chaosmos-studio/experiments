extends SceneTree

const Puzzle = preload("res://scripts/puzzle.gd")
const Session = preload("res://scripts/session.gd")
const Growth = preload("res://scripts/growth.gd")
var checks: int = 0
var failures: int = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var levels: Array = Puzzle.load_levels()
	check(levels.size() == 30, "Campaign has thirty levels")
	var previous: int = 0
	for level: Dictionary in levels:
		var state: Array = Puzzle.initial(level)
		check(not Puzzle.won(level, state), "Level starts unsolved")
		var result: Dictionary = Puzzle.solve(level, state)
		check(result.status == "solved", "Native rules find a solution")
		check(result.route.size() == int(level.par), "Independent native BFS confirms shortest route")
		check(int(level.par) >= previous, "Shortest route never drops")
		previous = int(level.par)
		for move: Array in level.solution:
			var next: Array = Puzzle.apply(level, state, move)
			check(not next.is_empty(), "Generated move is legal in native rules")
			if next.is_empty():
				break
			var occupied: Array = level.walls.duplicate()
			for i: int in range(next.size()):
				for cell_value: Variant in next[i]:
					check(not cell_value in occupied, "No overlapping seeds or stones")
					occupied.append(cell_value)
				for old_cell: Variant in state[i]:
					if old_cell in level.goals[i]:
						check(old_cell in next[i], "Rooted seed never moves")
			state = next
		check(Puzzle.won(level, state), "Stored witness blooms every pair")
		check(Puzzle.options(level, state).is_empty(), "Completed garden stays still")
	var example: Dictionary = {"size":4,"walls":[5],"goals":[[14,15]],"start":[[0,1]]}
	check(Puzzle.apply(example, [[0,1]], [0,0,1]).is_empty(), "Swept corner blocks a turn even when landing is clear")
	example.walls = []
	check(not Puzzle.apply(example, [[0,1]], [0,0,1]).is_empty(), "Removing corner obstacle opens the same turn")
	example.goals = [[1,5]]
	check(Puzzle.apply(example, [[0,1]], [0,0,1]).is_empty(), "Cannot move a seed off its soil")
	check(not Puzzle.apply(example, [[0,1]], [0,1,-1]).is_empty(), "Can pivot around a rooted seed")
	check(Puzzle.apply(example, [[0,1]], [99,0,1]).is_empty(), "Invalid piece is rejected")
	check(typeof(ProjectSettings.get_setting("display/window/handheld/orientation")) == TYPE_INT, "Orientation is an integer")
	for action: String in ["undo","retry","hint","back"]:
		check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "Keyboard action has events")
	var first: Dictionary = levels[0]
	var opening: Array = Puzzle.initial(first)
	var moved: Array = Puzzle.apply(first, opening, first.solution[0])
	var run: Dictionary = {"revision":1, "level":0, "state":moved, "history":[opening], "moves":1}
	var recovered: Dictionary = Session.recover(first, run, 0)
	check(not recovered.is_empty() and recovered.state == moved and recovered.history[0] == opening, "Resume keeps the board and undo chain")
	check(Session.recover(first, run, 1).is_empty(), "A saved run cannot cross level boundaries")
	var corrupt: Dictionary = run.duplicate(true)
	corrupt.state = first.goals.duplicate(true)
	check(Session.recover(first, corrupt, 0).is_empty(), "A skipped move in a save is rejected")
	corrupt = run.duplicate(true)
	corrupt.history = [[[0, 0]]]
	check(Session.recover(first, corrupt, 0).is_empty(), "A corrupted undo chain is rejected")
	corrupt = run.duplicate(true)
	corrupt.state[0][0] = 1.5
	check(Session.recover(first, corrupt, 0).is_empty(), "Fractional save coordinates are rejected")
	corrupt = run.duplicate(true)
	corrupt.moves = 2
	check(Session.recover(first, corrupt, 0).is_empty(), "Save move count agrees with history")
	check(Session.next_garden(30, 29, {"0":2, "29":18}) == 1, "Finishing the last garden returns to an unfinished garden")
	var all_done: Dictionary = {}
	for i: int in range(30):
		all_done[str(i)] = 99
	check(Session.next_garden(30, 29, all_done) == -1, "Ending is available only after every garden is complete")
	var growth: Growth = Growth.new()
	growth.reset(first, opening)
	growth.changed(first, opening, moved, false)
	check(growth.roots.size() == 1 and not growth.particles.is_empty(), "A planted seed starts a root growth event")
	var finished: Array = Puzzle.apply(first, moved, first.solution[1])
	growth.changed(first, moved, finished, false)
	check(growth.flowers.has(0), "Finishing a pair starts its bloom")
	growth.advance(0.1, true)
	check(growth.particles.is_empty() and growth.flower_age(0) >= 1.0, "Reduced motion settles growth and removes particles")
	growth.reset(first, opening)
	check(growth.roots.is_empty() and growth.flowers.is_empty(), "Undo/reset removes obsolete growth state")
	growth.changed(first, opening, finished, false)
	growth.advance(5.0, false)
	check(growth.particles.is_empty(), "Growth particles expire")
	var blocked: Dictionary = {"size":4,"walls":[5],"goals":[[14,15]],"start":[[0,1]]}
	check(Puzzle.explain(blocked, [[0,1]], 0, 1, 1).kind == "corner", "Feedback identifies swept-corner blockage")
	blocked.walls = [4]
	check(Puzzle.explain(blocked, [[0,1]], 0, 1, 1).kind == "landing", "Feedback identifies an occupied landing")
	blocked.walls = []
	check(Puzzle.explain(blocked, [[0,1]], 0, 1, 1).kind == "legal", "Legal landing is not described as blocked")
	blocked.goals = [[1,5]]
	check(Puzzle.explain(blocked, [[0,1]], 0, 1, 1).kind == "root", "Rooted seed gets a distinct explanation")
	print("checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
