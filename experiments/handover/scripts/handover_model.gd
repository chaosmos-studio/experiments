extends RefCounted
class_name HandoverModel

const CREW: Array[String] = ["Mara", "Ivo", "Sol"]
const STAGES: Array[Dictionary] = [
	{"title": "Wake the water", "line": "The first sunrise begins with a single drop.", "tasks": ["Wind the pump", "Open the valve"], "owners": [0, 1], "requires": [-1, 0], "done": "Water finds the sleeping roots."},
	{"title": "Carry the light", "line": "The vines will lift only while someone keeps them open.", "tasks": ["Hold the vines", "Carry the prism", "Focus the beam"], "owners": [1, 2, 0], "requires": [-1, 0, 1], "done": "A thin ribbon of gold crosses the room."},
	{"title": "Make a morning", "line": "One hand for the shutter. One for the engine. One for the sky.", "tasks": ["Lift the shutter", "Turn the engine", "Open the sky"], "owners": [2, 0, 1], "requires": [-1, 0, 1], "done": "The greenhouse remembers dawn."},
]

var stage: int = 0
var selected: int = 0
var assignments: Array[int] = [-1, -1, -1]
var cleared: bool = false
var finished: bool = false
var shifts: int = 0

func select_worker(index: int) -> void:
	if index < 0 or index >= CREW.size() or finished:
		return
	if selected != index:
		shifts += 1
	selected = index

func assign(task: int) -> String:
	if finished or cleared:
		return "wait"
	var tasks: Array = STAGES[stage]["tasks"]
	if task < 0 or task >= tasks.size():
		return "invalid"
	var owners: Array = STAGES[stage]["owners"]
	if selected != int(owners[task]):
		return "wrong_worker"
	var prerequisites: Array = STAGES[stage]["requires"]
	var required: int = int(prerequisites[task])
	if required >= 0 and assignments[int(owners[required])] != required:
		return "locked"
	assignments[selected] = task
	if is_stage_complete():
		cleared = true
		return "complete"
	return "assigned"

func is_stage_complete() -> bool:
	var owners: Array = STAGES[stage]["owners"]
	for task: int in range(owners.size()):
		if assignments[int(owners[task])] != task:
			return false
	return true

func advance() -> void:
	if not cleared:
		return
	if stage == STAGES.size() - 1:
		finished = true
		return
	stage += 1
	assignments = [-1, -1, -1]
	cleared = false

func restart() -> void:
	stage = 0
	selected = 0
	assignments = [-1, -1, -1]
	cleared = false
	finished = false
	shifts = 0
