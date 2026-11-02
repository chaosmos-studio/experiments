extends RefCounted

enum Mode { READY, RUNNING, CRASHED }

class Gate extends RefCounted:
	var x: float
	var side: int
	var scored: bool = false

	func _init(at_x: float, at_side: int) -> void:
		x = at_x
		side = at_side


const PLAYER_X: float = 170.0
const TOP_Y: float = 470.0
const BOTTOM_Y: float = 970.0
const GATE_WIDTH: float = 56.0
const GATE_SPACING: float = 430.0

var mode: Mode = Mode.READY
var side: int = 1
var player_y: float = BOTTOM_Y
var distance: float = 0.0
var score: int = 0
var best: int = 0
var gates: Array[Gate] = []


func _init() -> void:
	reset()


func reset() -> void:
	mode = Mode.READY
	side = 1
	player_y = BOTTOM_Y
	distance = 0.0
	score = 0
	gates.clear()
	for index: int in 3:
		gates.append(Gate.new(690.0 + GATE_SPACING * float(index), 1 - index % 2))


func start() -> void:
	if mode != Mode.RUNNING:
		reset()
		mode = Mode.RUNNING


func shift() -> bool:
	if mode != Mode.RUNNING:
		return false
	side = 1 - side
	return true


func step(delta: float) -> void:
	if mode != Mode.RUNNING:
		return
	var frame: float = minf(delta, 0.05)
	var speed: float = minf(550.0, 310.0 + distance * 0.018)
	player_y = move_toward(player_y, BOTTOM_Y if side == 1 else TOP_Y, 1150.0 * frame)
	distance += speed * frame
	for gate: Gate in gates:
		gate.x -= speed * frame
		if not gate.scored and gate.x + GATE_WIDTH * 0.5 < PLAYER_X - 23.0:
			gate.scored = true
			score += 1
			best = maxi(best, score)
		if absf(gate.x - PLAYER_X) < GATE_WIDTH * 0.5 + 22.0:
			if (gate.side == 0 and player_y < 700.0) or (gate.side == 1 and player_y > 740.0):
				mode = Mode.CRASHED
				return
	while gates[0].x < -100.0:
		gates.pop_front()
	while gates[-1].x < 1100.0:
		var last: Gate = gates[-1]
		gates.append(Gate.new(last.x + GATE_SPACING, 1 - last.side))
