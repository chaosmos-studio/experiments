extends SceneTree

const Puzzle = preload("res://scripts/puzzle.gd")
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
	print("checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
