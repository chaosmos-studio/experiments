extends RefCounted
## State = removed screw mask + ordered, unmatched screw IDs in the tray.

const CAPACITY := 7
var plates: Array = []
var screws: Array = []
var plate_masks: Array[int] = []
var blockers: Array = []
var all_mask: int = 0
var visits: int = 0
var search_limit: int = 150000
var exhausted := false
var dead: Dictionary = {}
var pass_limit := 0

func configure(data: Dictionary) -> void:
	plates = data.plates.duplicate(true)
	screws = data.screws.duplicate(true)
	plate_masks.clear()
	blockers.clear()
	all_mask = (1 << screws.size()) - 1
	for _p in plates:
		plate_masks.append(0)
	for i in screws.size():
		plate_masks[int(screws[i].plate)] |= 1 << i
	for screw in screws:
		var covers: Array[int] = []
		var pos := Vector2(float(screw.x), float(screw.y))
		for p in range(int(screw.plate) + 1, plates.size()):
			var r: Array = plates[p].rect
			if Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).has_point(pos):
				covers.append(p)
		blockers.append(covers)

func plate_active(plate: int, mask: int) -> bool:
	return (mask & plate_masks[plate]) != plate_masks[plate]

func exposed(index: int, mask: int) -> bool:
	if index < 0 or index >= screws.size() or mask & (1 << index):
		return false
	for p in blockers[index]:
		if plate_active(p, mask):
			return false
	return true

func settle(line: Array[int]) -> Dictionary:
	var result: Array[int] = line.duplicate()
	var cleared: Array[int] = []
	var i := 0
	while i + 2 < result.size():
		var color := int(screws[result[i]].color)
		if int(screws[result[i+1]].color) == color and int(screws[result[i+2]].color) == color:
			for _j in 3:
				cleared.append(result[i])
				result.remove_at(i)
			i = maxi(0, i-2)
		else:
			i += 1
	return {"tray": result, "cleared": cleared, "sets": cleared.size() / 3}

func collect(index: int, mask: int, line: Array[int]) -> Dictionary:
	if line.size() >= CAPACITY or not exposed(index, mask):
		return {}
	var next: Array[int] = line.duplicate()
	next.append(index)
	var result := settle(next)
	result.mask = mask | (1 << index)
	return result

func put_back(index: int, mask: int, line: Array[int]) -> Dictionary:
	if index < 0 or index >= screws.size() or not line.has(index) or not (mask & (1 << index)):
		return {}
	var next: Array[int] = line.duplicate()
	next.erase(index)
	var result := settle(next)
	result.mask = mask & ~(1 << index)
	return result

func is_won(mask: int, line: Array[int]) -> bool:
	return mask == all_mask and line.is_empty()

func solve(mask: int = 0, line: Array[int] = [], limit: int = 60000, allow_returns: bool = true) -> Array[int]:
	# Positive actions collect a screw; -(id+2) returns it; -1 marks completion.
	# First seek a forward solution. Then verify single returns and short
	# front/back return sequences followed by forward play. All hints have a
	# complete checked continuation; this bounded search is not exhaustive.
	visits = 0
	search_limit = limit
	var cut_short := false
	var route := _attempt(mask, line)
	if not route.is_empty() or not allow_returns:
		return route
	cut_short = exhausted
	for index in line:
		var next := put_back(index, mask, line)
		route = _attempt(int(next.mask), next.tray)
		cut_short = cut_short or exhausted
		if not route.is_empty():
			route.push_front(-index-2)
			return route
		if visits >= search_limit:
			exhausted = true
			return []
	for reverse_order in [true, false]:
		var current_mask := mask
		var current: Array[int] = line.duplicate()
		var order: Array[int] = line.duplicate()
		if reverse_order:
			order.reverse()
		var prefix: Array[int] = []
		for index in order:
			if not current.has(index):
				continue
			var next := put_back(index, current_mask, current)
			current_mask = int(next.mask)
			current.assign(next.tray)
			prefix.append(-index-2)
			route = _attempt(current_mask, current)
			cut_short = cut_short or exhausted
			if not route.is_empty():
				prefix.append_array(route)
				return prefix
			if visits >= search_limit:
				exhausted = true
				return []
	exhausted = cut_short
	return []

func _attempt(mask: int, line: Array[int]) -> Array[int]:
	dead.clear()
	exhausted = false
	pass_limit = mini(search_limit, visits + 5000)
	return _search(mask, line)

func _search(mask: int, line: Array[int]) -> Array[int]:
	if is_won(mask, line):
		return [-1]
	if line.size() >= CAPACITY:
		return []
	if visits >= pass_limit:
		exhausted = true
		return []
	var key := str(mask) + ":" + str(line)
	if dead.has(key):
		return []
	visits += 1
	var tail := -1 if line.is_empty() else int(screws[line.back()].color)
	var choices: Array[int] = []
	for i in screws.size():
		if exposed(i, mask):
			choices.append(i)
	choices.sort_custom(func(a: int, b: int): return int(int(screws[a].color) == tail) > int(int(screws[b].color) == tail))
	for index in choices:
		var next := collect(index, mask, line)
		var route := _search(int(next.mask), next.tray)
		if not route.is_empty():
			route.push_front(index)
			return route
		if exhausted:
			return []
	dead[key] = true
	return []
