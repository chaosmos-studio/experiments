extends RefCounted

enum Mode { READY, RUNNING, CRASHED }

class Gate extends RefCounted:
	var y: float
	var gap_x: float
	var scored: bool = false

	func _init(at_y: float, at_gap_x: float) -> void:
		y = at_y
		gap_x = at_gap_x


const PLAYER_Y: float = 720.0
const GAP_HALF_WIDTH: float = 112.0
const GATE_THICKNESS: float = 52.0
const GAP_SEQUENCE: Array[float] = [360.0, 510.0, 240.0, 455.0, 195.0, 545.0, 300.0, 420.0]

var mode: Mode = Mode.READY
var player_x: float = 360.0
var target_x: float = 360.0
var charge: float = 1.0
var slow: bool = false
var distance: float = 0.0
var score: int = 0
var best: int = 0
var gates: Array[Gate] = []
var next_gap: int = 0


func _init() -> void:
	reset()


func reset() -> void:
	mode = Mode.READY
	player_x = 360.0
	target_x = 360.0
	charge = 1.0
	slow = false
	distance = 0.0
	score = 0
	next_gap = 0
	gates.clear()
	for index: int in 3:
		gates.append(Gate.new(230.0 - float(index) * 430.0, _next_gap()))


func start() -> void:
	if mode != Mode.RUNNING:
		reset()
		mode = Mode.RUNNING


func steer(x: float) -> void:
	target_x = clampf(x, 48.0, 672.0)


func shift() -> bool:
	if mode != Mode.RUNNING or (not slow and charge < 0.12):
		return false
	slow = not slow
	return true


func step(delta: float) -> void:
	if mode != Mode.RUNNING:
		return
	var frame: float = minf(delta, 0.05)
	if slow:
		charge = maxf(0.0, charge - 0.42 * frame)
		if charge <= 0.0:
			slow = false
	else:
		charge = minf(1.0, charge + 0.19 * frame)
	player_x = move_toward(player_x, target_x, 780.0 * frame)
	var speed: float = minf(570.0, 325.0 + distance * 0.016)
	var travel: float = speed * (0.38 if slow else 1.0) * frame
	distance += travel
	for gate: Gate in gates:
		gate.y += travel
		if not gate.scored and gate.y - GATE_THICKNESS * 0.5 > PLAYER_Y + 25.0:
			gate.scored = true
			score += 1
			best = maxi(best, score)
		if absf(gate.y - PLAYER_Y) < GATE_THICKNESS * 0.5 + 22.0:
			if absf(player_x - gate.gap_x) > GAP_HALF_WIDTH - 22.0:
				mode = Mode.CRASHED
				return
	while gates[0].y > 1540.0:
		gates.pop_front()
	while gates[-1].y > -500.0:
		gates.append(Gate.new(gates[-1].y - 430.0, _next_gap()))


func _next_gap() -> float:
	var result: float = GAP_SEQUENCE[next_gap % GAP_SEQUENCE.size()]
	next_gap += 1
	return result
