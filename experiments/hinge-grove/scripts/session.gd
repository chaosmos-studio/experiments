extends RefCounted
const Puzzle = preload("res://scripts/puzzle.gd")

## Accept a saved run only if its entire undo chain is legal for this level.
static func recover(level: Dictionary, raw: Dictionary, index: int) -> Dictionary:
	if int(raw.get("revision", 0)) != 1 or int(raw.get("level", -1)) != index:
		return {}
	var stored_history: Variant = raw.get("history")
	var stored_state: Variant = raw.get("state")
	if not stored_history is Array or not stored_state is Array:
		return {}
	if stored_history.size() > 2000 or int(raw.get("moves", -1)) != stored_history.size():
		return {}
	var history: Array = []
	for entry: Variant in stored_history:
		var normalized: Array = _normalize(entry, level)
		if normalized.is_empty():
			return {}
		history.append(normalized)
	var state: Array = _normalize(stored_state, level)
	if state.is_empty():
		return {}
	var sequence: Array = history.duplicate(true)
	sequence.append(state)
	var before: Array = Puzzle.initial(level)
	if sequence[0] != before:
		return {}
	for i: int in range(1, sequence.size()):
		var legal: bool = false
		for option: Dictionary in Puzzle.options(level, before):
			var next: Array = Puzzle.apply(level, before, [option.piece, option.pivot, option.turn])
			if next == sequence[i]:
				legal = true
				break
		if not legal:
			return {}
		before = sequence[i]
	return {"state": state, "history": history, "moves": history.size()}

static func _normalize(value: Variant, level: Dictionary) -> Array:
	if not value is Array or value.size() != level.start.size():
		return []
	var result: Array = []
	for pair: Variant in value:
		if not pair is Array or pair.size() != 2:
			return []
		var cells: Array = []
		for cell: Variant in pair:
			if not (cell is int or cell is float) or float(cell) != float(int(cell)):
				return []
			if int(cell) < 0 or int(cell) >= int(level.size) * int(level.size):
				return []
			cells.append(int(cell))
		cells.sort()
		result.append(cells)
	return result

static func next_garden(count: int, current: int, completed: Dictionary) -> int:
	for step: int in range(count):
		var candidate: int = (current + 1 + step) % count
		if not completed.has(str(candidate)):
			return candidate
	return -1
