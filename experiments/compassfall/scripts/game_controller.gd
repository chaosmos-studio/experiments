extends Node2D

const PILOT_SCRIPT: Script = preload("res://scripts/player.gd")
const CARGO_SCRIPT: Script = preload("res://scripts/cargo.gd")
const WORLD_SCRIPT: Script = preload("res://scripts/world_view.gd")
const HUD_SCRIPT: Script = preload("res://scripts/hud.gd")

var level_index: int = 0
var level: Dictionary = {}
var gravity_direction: Vector2 = Vector2.DOWN
var phase: int = 0
var collected: Array[bool] = []
var pad_armed: bool = false
var playing: bool = false
var finished: bool = false
var run_time: float = 0.0
var deaths: int = 0
var shifts: int = 0
var last_shift: float = -1.0
var room: Node2D
var world: CompassWorldView
var pilot: CompassPilot
var cargo: CompassCargo
var bridges: Array[CollisionShape2D] = []
var camera: Camera2D
var hud: CompassHud
var sound: AudioStreamPlayer
var audio_enabled: bool = true
var sound_paths: Dictionary = {
	"shift": "res://assets/audio/sfx/shift.wav",
	"jump": "res://assets/audio/sfx/jump.wav",
	"spark": "res://assets/audio/sfx/spark.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"door": "res://assets/audio/sfx/door.wav",
}


func _ready() -> void:
	world = WORLD_SCRIPT.new() as CompassWorldView
	add_child(world)
	camera = Camera2D.new()
	camera.position = Vector2(960, 540)
	add_child(camera)
	camera.make_current()
	sound = AudioStreamPlayer.new()
	add_child(sound)
	hud = HUD_SCRIPT.new() as CompassHud
	add_child(hud)
	hud.begin_pressed.connect(_on_begin)
	hud.pause_pressed.connect(_on_pause)
	hud.jump_pressed.connect(func() -> void: if is_instance_valid(pilot): pilot.queue_touch_jump())
	hud.move_pressed.connect(func(axis: float) -> void: if is_instance_valid(pilot): pilot.touch_axis = axis)
	hud.shift_pressed.connect(_shift)
	_load_level(0)
	hud.show_panel("COMPASSFALL", "A little pilot. A station losing its light.\n\nRun and jump through the clockwork. Turn gravity to move yourself and cargo. Each turn changes the light bridges. Collect three sparks and reach the gold door.", "START SHIFT")


func _process(delta: float) -> void:
	if playing and not finished:
		run_time += delta
		_update_hud()
	if is_instance_valid(pilot):
		var target: Vector2 = Vector2(960, 540) + (pilot.position - Vector2(960, 540)) * 0.1
		camera.position = camera.position.lerp(target, minf(delta * 3.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	if key == KEY_ENTER and not playing:
		_on_begin()
	elif key == KEY_Q and playing:
		_shift(-1)
	elif key == KEY_E and playing:
		_shift(1)
	elif key == KEY_R and playing:
		_restart()
	elif key == KEY_P and playing:
		_on_pause()


func _physics_process(_delta: float) -> void:
	if playing and not finished and is_instance_valid(pilot) and world.door_open:
		if pilot.position.distance_to(level["exit"]) < 65.0:
			_advance()


func _load_level(index: int) -> void:
	level_index = index
	level = CompassLevels.get_level(index)
	gravity_direction = Vector2.DOWN
	phase = 0
	pad_armed = false
	collected.clear()
	for ignored: Vector2 in level["shards"]:
		collected.append(false)
	if is_instance_valid(room):
		remove_child(room)
		room.queue_free()
	room = Node2D.new()
	room.name = "Compartment"
	add_child(room)
	bridges.clear()
	for wall: Rect2 in level["walls"]:
		_add_wall(wall, false)
	for bridge: Rect2 in level["phase_walls"]:
		_add_wall(bridge, true)
	for hazard: Rect2 in level["hazards"]:
		_add_hazard(hazard)
	for spark_index: int in range(collected.size()):
		_add_spark(level["shards"][spark_index], spark_index)
	if level["pad"] != Vector2.ZERO:
		_add_pad(level["pad"])
		cargo = CARGO_SCRIPT.new() as CompassCargo
		cargo.position = level["crate"]
		room.add_child(cargo)
	else:
		cargo = null
	pilot = PILOT_SCRIPT.new() as CompassPilot
	pilot.position = level["start"]
	room.add_child(pilot)
	pilot.control_enabled = playing
	pilot.jumped.connect(_on_pilot_jumped)
	world.level = level
	world.phase = phase
	world.collected = collected.duplicate()
	world.pad_armed = false
	world.door_open = false
	world.gravity_direction = gravity_direction
	hud.set_hint(level["hint"])
	_update_hud()
	print("COMPASSFALL_ROOM ", index)


func _add_wall(rect: Rect2, is_bridge: bool) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 6
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.disabled = is_bridge
	body.add_child(shape)
	room.add_child(body)
	if is_bridge:
		bridges.append(shape)


func _add_hazard(rect: Rect2) -> void:
	var area: Area2D = _make_area(rect.get_center(), rect.size + Vector2(0, 14), 2)
	area.body_entered.connect(_on_hazard_body)


func _add_spark(pos: Vector2, index: int) -> void:
	var area: Area2D = _make_area(pos, Vector2(66, 72), 2)
	area.body_entered.connect(_on_spark_body.bind(index, area))


func _add_pad(pos: Vector2) -> void:
	var area: Area2D = _make_area(pos + Vector2(0, -15), Vector2(106, 56), 4)
	area.body_entered.connect(_on_pad_body)


func _make_area(pos: Vector2, size: Vector2, mask: int) -> Area2D:
	var area: Area2D = Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = mask
	area.monitoring = true
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	room.add_child(area)
	return area


func _on_hazard_body(body: Node2D) -> void:
	if body == pilot and playing:
		deaths += 1
		_play_sound("hit")
		_restart()


func _on_spark_body(body: Node2D, index: int, area: Area2D) -> void:
	if body != pilot or not playing or collected[index]:
		return
	collected[index] = true
	print("COMPASSFALL_SPARK ", level_index, " ", index)
	world.collected = collected.duplicate()
	area.set_deferred("monitoring", false)
	_play_sound("spark")
	_update_door()
	_update_hud()


func _on_pad_body(body: Node2D) -> void:
	if body != cargo or pad_armed:
		return
	pad_armed = true
	world.pad_armed = true
	_play_sound("spark")
	_update_door()
	_update_hud()


func _update_door() -> void:
	world.door_open = not collected.has(false) and (level["pad"] == Vector2.ZERO or pad_armed)
	if world.door_open:
		_play_sound("door")


func _shift(step: int) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if not playing or finished or now - last_shift < 0.24:
		return
	last_shift = now
	gravity_direction = gravity_direction.rotated(step * PI * 0.5).round()
	phase = 1 - phase
	shifts += 1
	pilot.set_gravity_direction(gravity_direction)
	if is_instance_valid(cargo):
		cargo.gravity_direction = gravity_direction
		cargo.sleeping = false
	for bridge: CollisionShape2D in bridges:
		bridge.set_deferred("disabled", phase == 0)
	world.phase = phase
	world.gravity_direction = gravity_direction
	world.shift_origin = pilot.position
	world.shift_age = 0.0
	print("COMPASSFALL_SHIFT ", gravity_direction)
	_play_sound("shift")
	_update_hud()


func _advance() -> void:
	_play_sound("door")
	playing = false
	pilot.control_enabled = false
	if level_index + 1 >= CompassLevels.count():
		finished = true
		print("COMPASSFALL_WIN")
		hud.show_panel("THE STATION WAKES", "You carried the light through every shift.\n\nTime %s  •  Turns %d  •  Restarts %d\n\nThe dawn shift is yours." % [_format_time(run_time), shifts, deaths], "PLAY AGAIN")
		return
	_load_level(level_index + 1)
	hud.show_panel(level["name"], level["hint"] + "\n\nThree sparks open the door. Cargo plates must be armed too.", "ENTER ROOM")


func _restart() -> void:
	_load_level(level_index)
	playing = true
	pilot.control_enabled = true
	hud.hide_panel()
	print("COMPASSFALL_START ", level_index)


func _on_pause() -> void:
	if not playing:
		return
	playing = false
	pilot.control_enabled = false
	hud.show_panel("SHIFT PAUSED", "The station will wait for you.", "RESUME")


func _on_begin() -> void:
	if finished:
		finished = false
		run_time = 0.0
		deaths = 0
		shifts = 0
		_load_level(0)
	playing = true
	pilot.control_enabled = true
	hud.hide_panel()
	print("COMPASSFALL_START ", level_index)


func _play_sound(name: String) -> void:
	if not audio_enabled:
		return
	var stream: AudioStream = load(sound_paths[name]) as AudioStream
	if stream == null:
		return
	sound.stop()
	sound.stream = stream
	sound.play()


func _on_pilot_jumped() -> void:
	print("COMPASSFALL_JUMP")
	_play_sound("jump")


func _format_time(value: float) -> String:
	var seconds: int = int(value)
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _update_hud() -> void:
	if level.is_empty():
		return
	hud.set_status(level_index, level["name"], collected.count(true), collected.size(), level["pad"] != Vector2.ZERO, pad_armed, _format_time(run_time), gravity_direction)
