extends RefCounted

const SIZE: int = 4
const GOAL: Array[int] = [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4]
const SCRAMBLES: Array[Array] = [
	[["row", 0, 1], ["column", 1, -1]],
	[["column", 3, 1], ["row", 1, -1], ["column", 0, -1]],
	[["row", 3, 1], ["column", 2, 1], ["row", 0, -1], ["column", 1, 1]],
]

var level: int = 0
var cells: Array[int] = []
var moves: int = 0
var history: Array[Array] = []


func reset(next_level: int) -> void:
	level = clampi(next_level, 0, SCRAMBLES.size() - 1)
	cells = GOAL.duplicate()
	moves = 0
	history.clear()
	for instruction: Array in SCRAMBLES[level]:
		_apply(String(instruction[0]), int(instruction[1]), int(instruction[2]))


func turn(axis: String, index: int, direction: int) -> bool:
	if won() or (axis != "row" and axis != "column") or index < 0 or index >= SIZE or absi(direction) != 1:
		return false
	history.append(cells.duplicate())
	_apply(axis, index, direction)
	moves += 1
	return true


func undo() -> bool:
	if history.is_empty():
		return false
	var previous: Array = history.pop_back()
	cells.assign(previous)
	moves -= 1
	return true


func won() -> bool:
	return cells == GOAL


func _apply(axis: String, index: int, direction: int) -> void:
	var previous: Array[int] = cells.duplicate()
	for slot: int in SIZE:
		var destination: int = posmod(slot + direction, SIZE)
		if axis == "row":
			cells[index * SIZE + destination] = previous[index * SIZE + slot]
		else:
			cells[destination * SIZE + index] = previous[slot * SIZE + index]
