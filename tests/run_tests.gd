extends SceneTree

const Rules = preload("res://scripts/puzzle.gd")
var failures := 0
var assertions := 0

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save_path := "user://rivet.json"
	var had_save := FileAccess.file_exists(save_path)
	var prior_save := FileAccess.get_file_as_string(save_path) if had_save else ""
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	check(levels.size() == 36, "Campaign has 36 studies")
	var rules = Rules.new()
	var maximum_visits := 0
	for level_id in levels.size():
		var level: Dictionary = levels[level_id]
		rules.configure(level)
		var mask: int = 0
		for step in level.solution:
			var index := int(step)
			check(rules.exposed(index, mask), "Witness step must be exposed: %d/%d" % [level_id, index])
			var previous := mask
			mask = rules.collect(index, mask)
			check(mask != previous, "Legal collection changes the board")
			check(rules.collect(index, mask) == mask, "A screw cannot be collected twice")
			check(rules.occupancy(mask) < Rules.CAPACITY, "Witness route never overflows")
		check(mask == rules.all_mask, "Witness clears the board")
		check(rules.occupancy(mask) == 0, "Witness leaves no unmatched screws")
		var route: Array[int] = rules.solve(0, 60000)
		check(not route.is_empty(), "Runtime solver finds a route for study %d" % level_id)
		maximum_visits = maxi(maximum_visits, rules.visits)
		mask = 0
		for index in route:
			if index == -1:
				break
			check(rules.exposed(index, mask), "Solver only recommends exposed screws")
			mask = rules.collect(index, mask)
			check(rules.occupancy(mask) < Rules.CAPACITY, "Solver route never overflows")
		check(mask == rules.all_mask, "Solver route reaches completion")
	# Adversarial states test the loss condition and blocked-move rejection.
	rules.configure(levels[20])
	var rng := RandomNumberGenerator.new()
	rng.seed = 441
	var losses := 0
	var covered_rejections := 0
	for attempt in 100:
		var mask: int = 0
		while mask != rules.all_mask and rules.occupancy(mask) < Rules.CAPACITY:
			var choices: Array[int] = []
			for i in rules.screws.size():
				if rules.exposed(i, mask):
					choices.append(i)
				elif not mask & (1 << i):
					check(rules.collect(i, mask) == mask, "Covered screws cannot be removed")
					covered_rejections += 1
			var old := mask
			mask = rules.collect(choices[rng.randi_range(0, choices.size()-1)], mask)
			if rules.occupancy(mask) >= Rules.CAPACITY:
				losses += 1
				check(rules.solve(mask).is_empty(), "Full trays have no legal continuation")
				check(rules.occupancy(old) < Rules.CAPACITY, "Undo restores a playable state")
	check(losses > 0, "Campaign contains meaningful tray pressure")
	check(covered_rejections > 0, "Layer occlusion was exercised")
	# Exercise the real scene controller, not only the pure rules.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.sound_on = false
	game._load_level(0)
	game._take(0)
	check(game.tray.size() == 1, "UI controller adds a screw to the tray")
	game._undo()
	check(game.removed == 0 and game.tray.is_empty(), "UI undo restores board and tray")
	for index in [0, 3, 6]:
		game.animating = 0
		game._take(index)
	check(game.tray.is_empty() and game.matched == 1, "UI clears a matching triple")
	game._undo()
	check(game.tray.size() == 2 and game.matched == 0, "Undo reverses a triple clear")
	game._hint()
	check(game.hint_index >= 0, "Hint points to a safe screw")
	game._load_level(0)
	for index in levels[0].solution:
		game.animating = 0
		game._take(int(index))
	await create_timer(0.5).timeout
	check(game.screen == "won", "Complete tutorial shows a win")
	game._action("next")
	check(game.level_index == 1 and game.removed == 0, "Next study starts cleanly")
	game.queue_free()
	await process_frame
	if had_save:
		var restored := FileAccess.open(save_path, FileAccess.WRITE)
		restored.store_string(prior_save)
	else:
		DirAccess.remove_absolute(save_path)
	print("TEST_RESULT assertions=%d failures=%d solver_max_nodes=%d observed_losses=%d" % [assertions, failures, maximum_visits, losses])
	quit(1 if failures else 0)

