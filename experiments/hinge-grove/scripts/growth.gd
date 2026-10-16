extends RefCounted
## Visual state only. Puzzle rules never depend on animation.
var roots: Dictionary = {}
var flowers: Dictionary = {}
var particles: Array = []
var clock: float = 0.0

func reset(level: Dictionary, state: Array) -> void:
	roots.clear()
	flowers.clear()
	particles.clear()
	for i: int in range(state.size()):
		for cell: int in state[i]:
			if cell in level.goals[i]:
				roots[_key(i, cell)] = 3.0
		if state[i] == level.goals[i]:
			flowers[i] = 3.0

func changed(level: Dictionary, before: Array, after: Array, quiet: bool) -> void:
	for i: int in range(after.size()):
		for cell: int in after[i]:
			if cell in level.goals[i] and cell not in before[i]:
				roots[_key(i, cell)] = 3.0 if quiet else 0.0
				if not quiet:
					_emit(cell, i, 8, false)
		if after[i] == level.goals[i] and before[i] != after[i]:
			flowers[i] = 3.0 if quiet else 0.0
			if not quiet:
				for cell: int in after[i]:
					_emit(cell, i, 12, true)

func advance(delta: float, quiet: bool) -> void:
	clock += delta
	for key: String in roots:
		roots[key] = 3.0 if quiet else minf(3.0, float(roots[key]) + delta)
	for key: int in flowers:
		flowers[key] = 3.0 if quiet else minf(3.0, float(flowers[key]) + delta)
	if quiet:
		particles.clear()
		return
	for p: Dictionary in particles:
		p.age += delta
	particles = particles.filter(func(p: Dictionary) -> bool: return float(p.age) < float(p.life))

func root_age(piece: int, cell: int) -> float:
	return float(roots.get(_key(piece, cell), 3.0))

func flower_age(piece: int) -> float:
	return float(flowers.get(piece, 3.0))

static func pop(t: float) -> float:
	var u: float = clampf(t, 0.0, 1.0) - 1.0
	return 1.0 + 2.70158 * u * u * u + 1.70158 * u * u

func _key(piece: int, cell: int) -> String:
	return "%d:%d" % [piece, cell]

func _emit(cell: int, piece: int, count: int, petal: bool) -> void:
	for i: int in range(count):
		var angle: float = TAU * float(i) / float(count) + float(cell) * 0.43
		var velocity: Vector2 = Vector2(cos(angle) * (42.0 + i * 4.0), -75.0 - absf(sin(angle)) * 95.0)
		particles.append({"cell": cell, "piece": piece, "velocity": velocity, "age": 0.0, "life": 0.9 + (i % 4) * 0.12, "spin": angle, "petal": petal})
	while particles.size() > 96:
		particles.pop_front()
