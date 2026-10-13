extends RefCounted
## Pure puzzle rules. A state is a bit mask of screws already collected.

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

func counts(mask: int) -> Array[int]:
	var result: Array[int] = [0, 0, 0, 0, 0, 0]
	for i in screws.size():
		if mask & (1 << i):
			result[int(screws[i].color)] += 1
	for c in result.size():
		result[c] %= 3
	return result

func occupancy(mask: int) -> int:
	var total := 0
	for amount in counts(mask):
		total += amount
	return total

func collect(index: int, mask: int) -> int:
	if occupancy(mask) >= CAPACITY or not exposed(index, mask):
		return mask
	return mask | (1 << index)

func solve(mask: int = 0, limit: int = 150000) -> Array[int]:
	visits = 0
	search_limit = limit
	exhausted = false
	dead.clear()
	return _search(mask)

func _search(mask: int) -> Array[int]:
	if mask == all_mask:
		return [-1]
	if visits >= search_limit:
		exhausted = true
		return []
	if dead.has(mask) or occupancy(mask) >= CAPACITY:
		return []
	visits += 1
	var held := counts(mask)
	var choices: Array[int] = []
	for i in screws.size():
		if exposed(i, mask):
			choices.append(i)
	choices.sort_custom(func(a: int, b: int): return held[int(screws[a].color)] > held[int(screws[b].color)])
	for index in choices:
		var route := _search(mask | (1 << index))
		if not route.is_empty():
			route.push_front(index)
			return route
		if exhausted:
			return []
	dead[mask] = true
	return []

