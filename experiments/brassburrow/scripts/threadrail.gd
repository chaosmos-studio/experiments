extends Node2D

const PlayerScript := preload("res://scripts/grapple_player.gd")
const GroundScript := preload("res://scripts/course_ground.gd")
const UIScript := preload("res://scripts/mode_ui.gd")
const EffectsScript := preload("res://scripts/effects.gd")
const BEETLE_TEXTURE := preload("res://assets/beetle_walk.png")
const ANCHOR_TEXTURE := preload("res://assets/anchor.png")
const ISLANDS := GroundScript.ISLANDS
const ANCHOR_POSITIONS := [
	Vector2(335, 595), Vector2(735, 645), Vector2(1165, 695),
	Vector2(1610, 705), Vector2(2030, 760), Vector2(2360, 610)
]

var playing := false
var player: CharacterBody2D
var ui: CanvasLayer
var camera: Camera2D
var effects: Node2D
var ground: Node2D
var anchors: Array[Node2D] = []
var drones: Array[Dictionary] = []
var checkpoint := 0
var hearts := 3
var elapsed := 0.0
var water_time := 0.0
var shake := 0.0
var music: AudioStreamPlayer
var sounds: Array[AudioStreamPlayer] = []
var sound_index := 0


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("hook", [KEY_J])
	_bind("dash", [KEY_SPACE])
	_bind("reel", [KEY_Q])
	ground = GroundScript.new()
	ground.z_index = -10
	add_child(ground)
	for location in ANCHOR_POSITIONS:
		var anchor := Node2D.new()
		anchor.position = location
		add_child(anchor)
		var art := Sprite2D.new()
		art.texture = ANCHOR_TEXTURE
		art.scale = Vector2.ONE * 0.72
		art.position.y = -28
		anchor.add_child(art)
		anchors.append(anchor)
	for index in 5:
		var sprite := Sprite2D.new()
		sprite.texture = BEETLE_TEXTURE
		sprite.hframes = 4
		sprite.vframes = 4
		sprite.scale = Vector2.ONE * 0.56
		sprite.z_index = 5
		add_child(sprite)
		drones.append({"node": sprite, "origin": ANCHOR_POSITIONS[index] + Vector2(10, -90), "phase": index * 1.8})
	player = PlayerScript.new()
	player.position = ISLANDS[0]
	add_child(player)
	player.hook_changed.connect(func(_attached: bool) -> void: try_hook())
	player.dashed.connect(_on_dashed)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2600
	camera.limit_bottom = 1500
	player.add_child(camera)
	camera.make_current()
	effects = EffectsScript.new()
	effects.z_index = 20
	add_child(effects)
	ui = UIScript.new()
	ui.title = "THREADRAIL"
	ui.description = "Grapple the glowing posts and swing between floating islands. Reel in, release at speed and dash through the currents to catch every landing."
	ui.controls = "MOVE  WASD / ARROWS     HOOK  J / CLICK     REEL  Q     DASH  SPACE"
	ui.primary_name = "HOOK"
	ui.secondary_name = "REEL"
	add_child(ui)
	ui.start_requested.connect(start_run)
	ui.primary_requested.connect(try_hook)
	ui.secondary_requested.connect(try_reel)
	ui.dash_requested.connect(func() -> void: player.try_dash())
	ui.touch_axis_changed.connect(func(axis: Vector2) -> void: player.touch_axis = axis)
	ui.update_status("ISLAND  0 / 5", "HEARTS  3")
	music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/audio/march.ogg")
	music.pitch_scale = 1.16
	music.volume_db = -20
	add_child(music)
	music.finished.connect(func() -> void:
		if playing:
			music.play()
	)
	for i in 5:
		var sound := AudioStreamPlayer.new()
		sound.volume_db = -8
		add_child(sound)
		sounds.append(sound)
	queue_redraw()


func _bind(name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(name, event)


func start_run() -> void:
	playing = true
	player.active = true
	player.release()
	player.position = ISLANDS[0]
	player.velocity = Vector2.ZERO
	player.invulnerable = 1.0
	checkpoint = 0
	hearts = 3
	elapsed = 0
	water_time = 0
	shake = 0
	ui.show_play()
	ui.toast("HOOK A POST AND LET THE ROPE PULL")
	music.play()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return
	if event.is_action_pressed("reel"):
		try_reel()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_hook(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not playing:
		return
	elapsed += delta
	shake = maxf(0, shake - delta * 1.8)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 10
	if ground.is_safe(player.position):
		water_time = maxf(0, water_time - delta * 3)
	else:
		water_time += delta
		player.velocity += Vector2(sin(elapsed * 2.0) * 130, cos(elapsed * 1.7) * 100) * delta
		if water_time > 2.25:
			_fall()
	for index in drones.size():
		var drone: Dictionary = drones[index]
		var sprite: Sprite2D = drone.node
		sprite.position = drone.origin + Vector2(sin(elapsed * 1.3 + drone.phase) * 55, cos(elapsed * 1.8 + drone.phase) * 75)
		sprite.frame = (4 if sin(elapsed + drone.phase) > 0 else 12) + int(elapsed * 11) % 4
		if sprite.position.distance_to(player.position) < 43 and player.invulnerable <= 0:
			_hit_by_drone(sprite.position)
	if checkpoint < 5 and player.position.distance_to(ISLANDS[checkpoint + 1]) < 145:
		checkpoint += 1
		water_time = 0
		shake = 0.45
		effects.burst(ISLANDS[checkpoint], Color("ffe3a1"), 35, 225)
		_play_sound(preload("res://assets/audio/harvest.wav"))
		ui.toast("LANDING %d / 5" % checkpoint)
		if checkpoint == 5:
			_end_run(true)
	ui.update_status("ISLAND  %d / 5" % checkpoint, "HEARTS  %d   %02d:%02d" % [hearts, int(elapsed) / 60, int(elapsed) % 60])
	queue_redraw()


func try_hook(aim: Vector2 = Vector2.INF) -> void:
	if not playing:
		return
	if is_instance_valid(player.hook):
		player.release()
		_play_sound(preload("res://assets/audio/swing.wav"))
		ui.toast("RELEASED · KEEP YOUR MOMENTUM")
		return
	var nearest: Node2D
	var best := 390.0
	for anchor in anchors:
		var distance := player.position.distance_to(anchor.position)
		if distance >= 390:
			continue
		var score := distance
		if aim != Vector2.INF:
			score = anchor.position.distance_to(aim) * 0.72 + distance * 0.28
		if score < best:
			best = score
			nearest = anchor
	if nearest == null:
		ui.toast("NO POST IN REACH")
		return
	player.attach(nearest)
	effects.burst(nearest.position, Color("f8d47e"), 14, 115)
	_play_sound(preload("res://assets/audio/build.wav"))


func try_reel() -> void:
	if not playing:
		return
	if not is_instance_valid(player.hook):
		ui.toast("HOOK A POST FIRST")
		return
	player.reeling = not player.reeling
	ui.toast("REELING IN" if player.reeling else "HOLDING LENGTH")
	_play_sound(preload("res://assets/audio/repair.wav"))


func _on_dashed() -> void:
	effects.burst(player.position, Color("d2eee0"), 20, 160)
	_play_sound(preload("res://assets/audio/dash.wav"))
	shake = minf(1, shake + 0.2)


func _hit_by_drone(source: Vector2) -> void:
	player.invulnerable = 1.1
	player.velocity = (player.position - source).normalized() * 530
	hearts -= 1
	shake = 1
	effects.burst(player.position, Color("e88d77"), 25, 170)
	_play_sound(preload("res://assets/audio/damage.wav"))
	ui.toast("DRONE STRIKE")
	if hearts <= 0:
		_end_run(false)


func _fall() -> void:
	hearts -= 1
	shake = 1
	effects.burst(player.position, Color("b5e8ee"), 29, 180)
	_play_sound(preload("res://assets/audio/damage.wav"))
	player.release()
	player.position = ISLANDS[checkpoint]
	player.velocity = Vector2.ZERO
	player.invulnerable = 1.4
	water_time = 0
	ui.toast("THE CURRENT BROUGHT YOU BACK")
	if hearts <= 0:
		_end_run(false)


func _end_run(won: bool) -> void:
	playing = false
	player.active = false
	player.touch_axis = Vector2.ZERO
	music.stop()
	ui.show_result(won, "Every landing held. You rode the rope all the way through in %d seconds." % int(elapsed) if won else "The current won this time. Hook the next post, reel in and release while you still have speed.")


func _play_sound(stream: AudioStream) -> void:
	var sound := sounds[sound_index]
	sound_index = (sound_index + 1) % sounds.size()
	sound.stop()
	sound.stream = stream
	sound.play()


func _draw() -> void:
	for anchor in anchors:
		var point := anchor.position + Vector2(0, -42)
		draw_circle(point, 30, Color("635541", 0.37))
		draw_arc(point, 25, 0, TAU, 28, Color("f6d878"), 6)
		draw_arc(point, 17, 0, TAU, 28, Color("7e5b3f"), 4)
		draw_circle(point, 7, Color("f9ecb2"))
	for index in range(1, ISLANDS.size()):
		var center: Vector2 = ISLANDS[index]
		var color := Color("f5db8d") if index <= checkpoint else Color("e2eed5", 0.73)
		draw_arc(center, 136, 0, TAU, 56, color, 7 if index == checkpoint + 1 else 3)
		for notch in 6:
			var angle := notch * TAU / 6.0
			draw_circle(center + Vector2(cos(angle), sin(angle)) * 137, 4, color)
	if playing and water_time > 0:
		draw_arc(player.position, 41, -PI / 2, -PI / 2 + TAU * minf(1, water_time / 2.25), 35, Color("f19b7c"), 7)
