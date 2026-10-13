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

func follow(rules, steps: Array, mask: int = 0, line: Array[int] = []) -> Dictionary:
	var state := {"mask": mask, "tray": line.duplicate()}
	for raw in steps:
		var action := int(raw)
		if action == -1:
			break
		var next: Dictionary = rules.collect(action, state.mask, state.tray) if action >= 0 else rules.put_back(-action-2, state.mask, state.tray)
		check(not next.is_empty(), "Every route action is legal")
		if next.is_empty():
			return state
		state = next
		check(state.tray.size() <= Rules.CAPACITY, "Tray stays within capacity")
	return state

func fixtures() -> void:
	var rules = Rules.new()
	var screws: Array = []
	for color in [0, 1, 0, 0, 1, 1, 2, 2, 2]:
		screws.append({"plate": 0, "x": 10, "y": 10, "color": color})
	rules.configure({"plates": [{"rect": [0, 0, 100, 100]}], "screws": screws})
	var state := follow(rules, [0, 1, 2, 3])
	check(state.tray == [0, 1, 2, 3], "A B A A preserves removal order without matching")
	check(rules.collect(0, state.mask, state.tray).is_empty(), "Duplicate collection is rejected")
	var returned: Dictionary = rules.put_back(1, state.mask, state.tray)
	check(returned.tray.is_empty() and returned.sets == 1, "Returning B closes A B A A into one triple")
	check(returned.mask == 13 and rules.exposed(1, returned.mask), "Return restores the original screw only")
	check(rules.put_back(0, returned.mask, returned.tray).is_empty(), "Matched screws cannot be returned")
	check(rules.put_back(-1, returned.mask, returned.tray).is_empty(), "Invalid returns are rejected")
	check(rules.settle([0, 2, 3, 1]).tray == [1], "Adjacent triple clears")
	check(rules.settle([0, 1, 2, 3]).tray.size() == 4, "Same colour counts with another order do not clear")
	check(rules.settle([0, 1, 4, 5, 2, 3]).tray.is_empty(), "Matching cascades after gap closure")
	check(not rules.is_won(rules.all_mask, [0, 1, 2]), "Empty board alone is not a win")
	check(rules.is_won(rules.all_mask, []), "Empty board and tray win")
	check(rules.solve(0, [], 0).is_empty() and rules.exhausted, "Budget exhaustion never invents a route")
	# Returning the last unmatched screw revives its panel and blocks the layer below.
	rules.configure({"plates": [{"rect": [0,0,100,100]}, {"rect": [0,0,100,100]}],
		"screws": [{"plate":0,"x":10,"y":10,"color":0}, {"plate":1,"x":20,"y":20,"color":1}]})
	check(not rules.exposed(0, 0), "Upper panel covers lower screw")
	check(rules.collect(0, 0, []).is_empty(), "Covered moves are rejected")
	state = follow(rules, [1])
	check(not rules.plate_active(1, state.mask) and rules.exposed(0, state.mask), "Empty upper panel disappears")
	returned = rules.put_back(1, state.mask, state.tray)
	check(rules.plate_active(1, returned.mask) and not rules.exposed(0, returned.mask), "Returned screw revives panel and occlusion")

func run() -> void:
	fixtures()
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
		var state := follow(rules, level.solution)
		check(rules.is_won(state.mask, state.tray), "Witness solves study %d" % level_id)
		var route: Array[int] = rules.solve(0, [], 60000, false)
		maximum_visits = maxi(maximum_visits, rules.visits)
		check(not route.is_empty(), "Runtime solver finds a forward route for study %d" % level_id)
		state = follow(rules, route)
		check(rules.is_won(state.mask, state.tray), "Runtime route wins")
		state = follow(rules, level.full_route)
		check(state.tray.size() == Rules.CAPACITY, "Every study has a route to tray pressure")
		for index in rules.screws.size():
			check(rules.collect(index, state.mask, state.tray).is_empty(), "Full tray rejects any collection")
		for index in state.tray:
			var returned: Dictionary = rules.put_back(index, state.mask, state.tray)
			check(returned.tray.size() < Rules.CAPACITY, "Every occupied slot can be returned from full")
			check(not (returned.mask & (1 << index)), "Full-tray return restores exact original screw")
	# Verify return-aware hints from an actual full tray, including every continuation action.
	rules.configure(levels[0])
	var full := follow(rules, levels[0].full_route)
	var recovery: Array[int] = rules.solve(full.mask, full.tray, 60000)
	check(not recovery.is_empty() and recovery[0] < -1, "Full tray has a verified return hint")
	var recovered := follow(rules, recovery, full.mask, full.tray)
	check(rules.is_won(recovered.mask, recovered.tray), "Return-aware hint route wins")
	var legacy_save := FileAccess.open(save_path, FileAccess.WRITE)
	legacy_save.store_string(JSON.stringify({"campaign_version": 2, "level": 8,
		"completed": {"2": true}, "unaided": {"2": true}, "legacy_completion": {"1": {"0": true}},
		"sound": false, "reduced_motion": true}))
	legacy_save.close()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.level_index == 0 and game.completed.is_empty() and game.unaided.is_empty(), "Changed campaign starts with fresh completion")
	check(game.legacy_completion["2"].has("2") and game.legacy_completion["1"].has("0"), "All older completion records are preserved")
	check(not game.sound_on and game.reduced_motion, "Migration preserves preferences")
	game._load_level(0)
	var demo: Dictionary = levels[0].return_demo
	for index in demo.takes:
		game._take(int(index))
	check(game.tray == demo.takes and game.matched == 0, "Rapid input keeps A B A A exactly ordered")
	var previous_mask: int = game.removed
	game._return_screw(int(demo.return_id))
	check(game.tray.is_empty() and game.matched == 1, "Controller return creates the adjacent triple")
	check(game.returns_used == 1 and game.hints_used == 0 and game.undos_used == 0, "Return is not assistance")
	check(not (game.removed & (1 << int(demo.return_id))), "Controller restores original screw")
	game._undo()
	check(game.removed == previous_mask and game.tray == demo.takes and game.matched == 0, "Undo reverses return and gap match exactly")
	game._load_level(0)
	for index in levels[0].full_route:
		game._take(int(index))
	check(game.screen == "full" and game.tray.size() == 7, "Full tray stays interactive")
	game._action("inspect")
	game._action("close")
	check(game.screen == "full" and game.hints_used == 0, "Closing inspection restores full state")
	game._hint()
	check(game.tray.has(game.hint_return_id), "Hint highlights a returnable tray screw")
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	var first_id: int = game.tray[0]
	game._unhandled_key_input(key)
	check(game.screen == "play" and not (game.removed & (1 << first_id)), "Number key returns occupied slot from full tray")
	game._undo()
	check(game.screen == "full" and game.tray == full.tray, "Undo restores full tray in exact order")
	# Returning is allowed in a clean solve.
	game._load_level(0)
	for index in demo.takes:
		game._take(int(index))
	game._return_screw(int(demo.return_id))
	for index in demo.after:
		game._take(int(index))
	await create_timer(0.5).timeout
	check(game.screen == "won" and game.tray.is_empty(), "Return-assisted sequence completes in the real scene")
	check(game.unaided.has("0") and game.returns_used == 1, "Returns retain unaided completion mark")
	game._action("next")
	check(game.level_index == 1 and game.removed == 0 and game.returns_used == 0, "Next study resets counters")
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.level_index == 1 and game.completed.has("0") and game.unaided.has("0"), "Version 3 progress persists on reload")
	# An old finish timer must not win a restarted or undone puzzle.
	game._load_level(0)
	for index in levels[0].solution:
		game._take(int(index))
	game._undo()
	await create_timer(0.5).timeout
	check(game.screen == "play" and not game.rules.is_won(game.removed, game.tray), "Undo cancels pending completion")
	game.queue_free()
	await process_frame
	if had_save:
		var restored := FileAccess.open(save_path, FileAccess.WRITE)
		restored.store_string(prior_save)
		restored.close()
	else:
		DirAccess.remove_absolute(save_path)
	print("TEST_RESULT assertions=%d failures=%d solver_max_nodes=%d" % [assertions, failures, maximum_visits])
	quit(1 if failures else 0)
