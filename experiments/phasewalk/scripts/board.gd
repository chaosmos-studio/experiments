extends RefCounted

const WIDTH: int = 7
const HEIGHT: int = 7
const START: Vector2i = Vector2i(0, 3)
const EXIT: Vector2i = Vector2i(6, 3)
const SHIFT_BUDGETS: Array[int] = [2, 3, 4]

var level: int = 0
var phase: int = 0
var position: Vector2i = START
var shifts: int = 0
var moves: int = 0


func reset(next_level: int) -> void:
	level = clampi(next_level, 0, SHIFT_BUDGETS.size() - 1)
	phase = 0
	position = START
	shifts = 0
	moves = 0


func walls(for_phase: int) -> PackedStringArray:
	match level:
		0:
			if for_phase == 0:
				return PackedStringArray(["...#...", "...#...", "...#...", "...#...", "...#...", "...#...", "...#..."])
			return PackedStringArray([".....#.", ".....#.", ".....#.", ".....#.", ".....#.", ".....#.", ".....#."])
		1:
			if for_phase == 0:
				return PackedStringArray(["..#....", "..#....", "..#....", "..#....", "..#....", "..#....", "..#...."])
			return PackedStringArray(["....#..", "....#..", "....#..", "....#..", "....#..", "....#..", "....#.."])
		_:
			if for_phase == 0:
				return PackedStringArray([".#...#.", ".#...#.", ".#...#.", ".#...#.", ".#...#.", ".#...#.", ".#...#."])
			return PackedStringArray(["...#...", "...#...", "...#...", "..##...", "...#...", "...#...", "...#..."])


func is_open(cell: Vector2i, for_phase: int) -> bool:
	if cell.x < 0 or cell.x >= WIDTH or cell.y < 0 or cell.y >= HEIGHT:
		return false
	var rows: PackedStringArray = walls(for_phase)
	return rows[cell.y][cell.x] != "#"


func move(direction: Vector2i) -> bool:
	if won():
		return false
	if absi(direction.x) + absi(direction.y) != 1:
		return false
	var target: Vector2i = position + direction
	if not is_open(target, phase):
		return false
	position = target
	moves += 1
	return true


func shift() -> bool:
	if won() or shifts >= SHIFT_BUDGETS[level] or not is_open(position, 1 - phase):
		return false
	phase = 1 - phase
	shifts += 1
	return true


func won() -> bool:
	return position == EXIT
