class_name GrovePuzzle
extends RefCounted

static func load_levels() -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	var levels: Array = data.levels
	for level: Dictionary in levels:
		level.size = int(level.size)
		level.par = int(level.par)
		for field: String in ["start", "goals", "solution"]:
			for row: Array in level[field]:
				for i: int in range(row.size()):
					row[i] = int(row[i])
		for i: int in range(level.walls.size()):
			level.walls[i] = int(level.walls[i])
	return levels

static func initial(level: Dictionary) -> Array:
	return level.start.duplicate(true)

static func won(level: Dictionary, state: Array) -> bool:
	for i: int in range(state.size()):
		if state[i] != level.goals[i]:
			return false
	return true

static func point(cell: int, size: int) -> Vector2i:
	return Vector2i(cell % size, cell / size)

static func options(level: Dictionary, state: Array, piece: int = -1, pivot: int = -1) -> Array:
	var result: Array = []
	var n: int = int(level.size)
	var occupied: Array = level.walls.duplicate()
	for pair: Array in state:
		occupied.append_array(pair)
	for i: int in range(state.size()):
		if piece >= 0 and piece != i:
			continue
		for end: int in range(2):
			var pin: int = int(state[i][end])
			var mobile: int = int(state[i][1 - end])
			if pivot >= 0 and pin != pivot:
				continue
			if mobile in level.goals[i]:
				continue
			var p: Vector2i = point(pin, n)
			var d: Vector2i = point(mobile, n) - p
			for sign_value: int in [-1, 1]:
				var turned: Vector2i = Vector2i(-d.y, d.x) * sign_value
				var target: Vector2i = p + turned
				var corner: Vector2i = p + d + turned
				if mini(target.x, target.y) < 0 or maxi(target.x, target.y) >= n:
					continue
				if mini(corner.x, corner.y) < 0 or maxi(corner.x, corner.y) >= n:
					continue
				var cell: int = target.y * n + target.x
				var sweep: int = corner.y * n + corner.x
				if cell in occupied or sweep in occupied:
					continue
				result.append({"piece": i, "pivot": pin, "turn": sign_value, "from": mobile, "to": cell, "corner": sweep})
	return result

static func apply(level: Dictionary, state: Array, move: Array) -> Array:
	if move.size() != 3:
		return []
	for option: Dictionary in options(level, state, int(move[0]), int(move[1])):
		if int(option.turn) == int(move[2]):
			var next: Array = state.duplicate(true)
			next[int(move[0])] = [mini(int(option.pivot), int(option.to)), maxi(int(option.pivot), int(option.to))]
			return next
	return []

static func key(state: Array) -> String:
	var parts: PackedStringArray = []
	for pair: Array in state:
		parts.append(str(int(pair[0])) + "," + str(int(pair[1])))
	return ";".join(parts)

static func solve(level: Dictionary, start: Array, cap: int = 100000) -> Dictionary:
	var queue: Array = [start]
	var first: String = key(start)
	var visited: Dictionary = {first: []}
	var cursor: int = 0
	while cursor < queue.size():
		var state: Array = queue[cursor]
		cursor += 1
		var state_key: String = key(state)
		if won(level, state):
			var route: Array = []
			while state_key != first:
				var record: Array = visited[state_key]
				route.push_front(record[1])
				state_key = String(record[0])
			return {"status": "solved", "route": route, "states": visited.size()}
		for choice: Dictionary in options(level, state):
			var move: Array = [choice.piece, choice.pivot, choice.turn]
			var next: Array = state.duplicate(true)
			next[int(choice.piece)] = [mini(int(choice.pivot), int(choice.to)), maxi(int(choice.pivot), int(choice.to))]
			var next_key: String = key(next)
			if not visited.has(next_key):
				visited[next_key] = [state_key, move]
				queue.append(next)
				if visited.size() >= cap:
					return {"status": "limit", "route": [], "states": visited.size()}
	return {"status": "stuck", "route": [], "states": visited.size()}

## Explain a failed gesture using the same quarter-turn geometry as options().
static func explain(level: Dictionary, state: Array, piece: int, mobile: int, turn: int) -> Dictionary:
	if piece < 0 or piece >= state.size() or mobile not in state[piece]:
		return {"message": "Choose a seed to move.", "cells": [], "kind": "selection"}
	if mobile in level.goals[piece]:
		return {"message": "This seed has roots. Move its partner.", "cells": [mobile], "kind": "root"}
	var pin: int = int(state[piece][0]) if int(state[piece][1]) == mobile else int(state[piece][1])
	for option: Dictionary in options(level, state, piece, pin):
		if int(option.turn) == turn:
			return {"message": "Release on the marked landing spot.", "cells": [], "kind": "legal"}
	var n: int = int(level.size)
	var p: Vector2i = point(pin, n)
	var d: Vector2i = point(mobile, n) - p
	var r: Vector2i = Vector2i(-d.y, d.x) * turn
	var target: Vector2i = p + r
	var corner: Vector2i = p + d + r
	if mini(target.x, target.y) < 0 or maxi(target.x, target.y) >= n or mini(corner.x, corner.y) < 0 or maxi(corner.x, corner.y) >= n:
		return {"message": "Keep the whole swing inside the garden.", "cells": [mobile], "kind": "edge"}
	var occupied: Array = level.walls.duplicate()
	for pair: Array in state:
		occupied.append_array(pair)
	var destination: int = target.y * n + target.x
	var sweep: int = corner.y * n + corner.x
	if destination in occupied:
		return {"message": "That landing spot is occupied.", "cells": [destination], "kind": "landing"}
	return {"message": "This corner blocks the swing.", "cells": [sweep], "kind": "corner"}
