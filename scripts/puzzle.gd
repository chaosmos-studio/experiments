extends RefCounted
## Finite block placement. All full rows and columns clear simultaneously.
const N := 6
var shapes: Array = []
var pieces: Array = []
var placements: Array = []
var goal := 0
var initial: int = 0
var visits := 0
var exhausted := false
var search_limit := 15000
var dead: Dictionary = {}

func configure(level: Dictionary, shape_data: Array) -> void:
	shapes = shape_data
	pieces = level.pieces.duplicate()
	goal = int(level.goal)
	initial = int(level.board)
	placements.clear()
	for shape in shapes:
		var options: Array = []
		for y in N:
			for x in N:
				var mask := shape_mask(shape, x, y)
				if mask != 0:
					options.append({"x": x, "y": y, "mask": mask})
		placements.append(options)

func shape_mask(shape: Array, x: int, y: int) -> int:
	var mask: int = 0
	for cell in shape:
		var cx := x + int(cell[0])
		var cy := y + int(cell[1])
		if cx < 0 or cy < 0 or cx >= N or cy >= N:
			return 0
		mask |= 1 << (cy*N+cx)
	return mask

func available(used: int) -> Array[int]:
	for start in range(0, pieces.size(), 3):
		var group: Array[int] = []
		for i in range(start, mini(start+3, pieces.size())):
			if not (used & (1 << i)):
				group.append(i)
		if not group.is_empty():
			return group
	return []

func settle(board: int) -> Dictionary:
	var clear: int = 0
	var lines := 0
	for axis in 2:
		for k in N:
			var mask: int = 0
			for j in N:
				mask |= 1 << (k*N+j if axis == 0 else j*N+k)
			if board & mask == mask:
				clear |= mask
				lines += 1
	return {"board": board & ~clear, "cleared": clear, "lines": lines}

func place(board: int, used: int, lines: int, piece: int, x: int, y: int) -> Dictionary:
	if not available(used).has(piece):
		return {}
	var mask := shape_mask(shapes[int(pieces[piece])], x, y)
	if mask == 0 or board & mask:
		return {}
	var next := settle(board | mask)
	next.used = used | (1 << piece)
	next.total = lines + int(next.lines)
	next.added = mask
	return next

func moves(board: int, used: int) -> Array:
	var options: Array = []
	for piece in available(used):
		for p in placements[int(pieces[piece])]:
			if not (board & int(p.mask)):
				var next := settle(board | int(p.mask))
				options.append({"piece": piece, "x": int(p.x), "y": int(p.y),
					"board": int(next.board), "lines": int(next.lines)})
	return options

func status(board: int, used: int, lines: int) -> String:
	if lines >= goal:
		return "won"
	return "lost" if moves(board, used).is_empty() else "play"

func solve(board: int, used: int = 0, lines: int = 0, limit: int = 15000) -> Array:
	visits = 0
	exhausted = false
	search_limit = limit
	dead.clear()
	return _search(board, used, lines)

func _search(board: int, used: int, lines: int) -> Array:
	if lines >= goal:
		return [Vector3i(-1, -1, -1)]
	if visits >= search_limit:
		exhausted = true
		return []
	var key := str(board) + ":" + str(used) + ":" + str(lines)
	if dead.has(key):
		return []
	visits += 1
	var options := moves(board, used)
	options.sort_custom(func(a: Dictionary, b: Dictionary):
		if a.lines != b.lines: return a.lines > b.lines
		if a.piece != b.piece: return a.piece < b.piece
		if a.y != b.y: return a.y < b.y
		return a.x < b.x)
	for p in options:
		var route := _search(int(p.board), used | (1 << int(p.piece)), lines+int(p.lines))
		if not route.is_empty():
			route.push_front(Vector3i(p.piece, p.x, p.y))
			return route
		if exhausted:
			return []
	dead[key] = true
	return []
