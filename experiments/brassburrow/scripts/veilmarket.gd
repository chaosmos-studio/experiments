extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const GroundScript := preload("res://scripts/market_ground.gd")
const UIScript := preload("res://scripts/mode_ui.gd")
const EffectsScript := preload("res://scripts/effects.gd")
const SHOPPER_TEXTURE := preload("res://assets/shopper_walk.png")
const WARDEN_TEXTURE := preload("res://assets/warden_walk.png")
const STONE_TEXTURE := preload("res://assets/stone.png")
const TREE_TEXTURE := preload("res://assets/tree.png")
const POD_TEXTURE := preload("res://assets/pod.png")

var playing := false
var player: CharacterBody2D
var camera: Camera2D
var ui: CanvasLayer
var effects: Node2D
var actors: Node2D
var crowds: Array[Dictionary] = []
var guards: Array[Dictionary] = []
var parcels: Array[Dictionary] = []
var delivered := 0
var lives := 3
var disguise_time := 0.0
var stun_cooldown := 0.0
var rng := RandomNumberGenerator.new()
var music: AudioStreamPlayer
var sounds: Array[AudioStreamPlayer] = []
var sound_index := 0


func _ready() -> void:
	rng.seed = 92741
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("attack", [KEY_J])
	_bind("dash", [KEY_SPACE])
	_bind("blend", [KEY_Q])
	var ground: Node2D = GroundScript.new()
	ground.z_index = -10
	add_child(ground)
	actors = Node2D.new()
	add_child(actors)
	_spawn_scenery()
	_spawn_crowds()
	_spawn_guards()
	player = PlayerScript.new()
	player.position = Vector2(95, 742)
	actors.add_child(player)
	player.swung.connect(_on_player_swung)
	player.dashed.connect(_on_dashed)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2380
	camera.limit_bottom = 1500
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.5
	player.add_child(camera)
	camera.make_current()
	effects = EffectsScript.new()
	effects.z_index = 20
	add_child(effects)
	_spawn_parcels()
	ui = UIScript.new()
	ui.title = "VEILMARKET"
	ui.description = "Slip through a busy night market.\nBorrow a stranger's look, collect three sealed parcels and reach the lantern gate before the wardens catch on."
	ui.controls = "MOVE  WASD / ARROWS     BLEND  Q     STUN  J / CLICK     DASH  SPACE"
	ui.primary_name = "STUN"
	ui.secondary_name = "BLEND"
	add_child(ui)
	ui.start_requested.connect(start_run)
	ui.primary_requested.connect(func() -> void: player.try_attack())
	ui.secondary_requested.connect(try_blend)
	ui.dash_requested.connect(func() -> void: player.try_dash())
	ui.touch_axis_changed.connect(func(axis: Vector2) -> void: player.touch_axis = axis)
	ui.update_status("PARCELS  0 / 3", "HEARTS  3")
	music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/audio/march.ogg")
	music.volume_db = -23.0
	music.pitch_scale = 0.85
	add_child(music)
	music.finished.connect(func() -> void:
		if playing:
			music.play()
	)
	for i in 5:
		var sound := AudioStreamPlayer.new()
		sound.volume_db = -9.0
		add_child(sound)
		sounds.append(sound)


func _bind(name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(name, event)


func _spawn_scenery() -> void:
	for index in 35:
		var x := rng.randf_range(50, 2320)
		var y := rng.randf_range(40, 1460)
		if y > 190 and y < 1320 and rng.randf() < 0.82:
			continue
		var prop := StaticBody2D.new()
		prop.position = Vector2(x, y)
		prop.collision_layer = 2
		prop.collision_mask = 0
		var shape := CircleShape2D.new()
		shape.radius = 20.0
		var collider := CollisionShape2D.new()
		collider.shape = shape
		prop.add_child(collider)
		var sprite := Sprite2D.new()
		sprite.texture = TREE_TEXTURE if index % 3 else STONE_TEXTURE
		sprite.scale = Vector2.ONE * 0.95
		sprite.position.y = -28
		sprite.modulate = Color("d1b9af") if index % 3 else Color("b4a6bb")
		prop.add_child(sprite)
		actors.add_child(prop)


func _spawn_crowds() -> void:
	for index in 34:
		var sprite := Sprite2D.new()
		sprite.texture = SHOPPER_TEXTURE
		sprite.hframes = 6
		sprite.vframes = 4
		sprite.scale = Vector2.ONE * rng.randf_range(0.45, 0.62)
		sprite.position = Vector2(rng.randf_range(240, 2150), rng.randf_range(250, 1180))
		sprite.z_index = 3
		var tint: Color = [Color("b8d2bc"), Color("d8b7a4"), Color("afbecb"), Color("e4d2aa")][index % 4]
		sprite.modulate = tint
		actors.add_child(sprite)
		crowds.append({"node": sprite, "origin": sprite.position, "phase": rng.randf_range(0, TAU), "tint": tint})


func _spawn_guards() -> void:
	for index in 9:
		var sprite := Sprite2D.new()
		sprite.texture = WARDEN_TEXTURE
		sprite.hframes = 6
		sprite.vframes = 4
		sprite.scale = Vector2.ONE * 0.70
		sprite.modulate = Color.WHITE
		sprite.position = Vector2(380 + index * 220, 330 + (index % 3) * 400)
		sprite.z_index = 4
		actors.add_child(sprite)
		guards.append({"node": sprite, "home": sprite.position, "facing": Vector2.LEFT, "state": 0, "suspicion": 0.0, "stun": 0.0, "phase": index * 1.5})


func _spawn_parcels() -> void:
	for x in [520, 1180, 1810]:
		var sprite := Sprite2D.new()
		sprite.texture = POD_TEXTURE
		sprite.scale = Vector2.ONE * 0.66
		sprite.position = Vector2(x, 755 + sin(x * 0.01) * 230)
		sprite.z_index = 2
		actors.add_child(sprite)
		parcels.append({"node": sprite, "found": false})


func start_run() -> void:
	playing = true
	player.active = true
	player.position = Vector2(95, 742)
	player.velocity = Vector2.ZERO
	player.appearance = Color.WHITE
	player.walk_texture = preload("res://assets/hero_walk.png")
	player.invulnerable = 1.0
	lives = 3
	delivered = 0
	disguise_time = 0.0
	stun_cooldown = 0.0
	for parcel in parcels:
		parcel.found = false
		parcel.node.visible = true
	for guard in guards:
		guard.state = 0
		guard.suspicion = 0.0
		guard.stun = 0.0
		guard.node.position = guard.home
	ui.show_play()
	ui.toast("TAKE THE PARCELS TO THE GATE")
	music.play()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return
	if event.is_action_pressed("blend"):
		try_blend()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player.try_attack(get_global_mouse_position() - player.global_position)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not playing:
		return
	disguise_time = maxf(0, disguise_time - delta)
	stun_cooldown = maxf(0, stun_cooldown - delta)
	if disguise_time == 0.0:
		player.appearance = Color.WHITE
		player.walk_texture = preload("res://assets/hero_walk.png")
	for index in crowds.size():
		var crowd: Dictionary = crowds[index]
		var sprite: Sprite2D = crowd.node
		crowd.phase += delta * (0.55 + index % 4 * 0.12)
		var drift := Vector2(sin(crowd.phase) * 28, cos(crowd.phase * 0.58) * 20)
		sprite.position = crowd.origin + drift
		sprite.frame = (6 if sin(crowd.phase) >= 0 else 18) + int(Time.get_ticks_msec() / 95 + index) % 6
		crowds[index] = crowd
	for index in guards.size():
		_update_guard(index, delta)
	for index in parcels.size():
		var parcel: Dictionary = parcels[index]
		if parcel.found:
			continue
		var node: Sprite2D = parcel.node
		node.position.y += sin(Time.get_ticks_msec() * 0.003 + index) * delta * 4
		if node.position.distance_to(player.position) < 45:
			parcel.found = true
			parcels[index] = parcel
			node.visible = false
			delivered += 1
			effects.burst(node.position, Color("ffe4a3"), 28, 220)
			_play_sound(preload("res://assets/audio/harvest.wav"))
			ui.toast("PARCEL %d / 3" % delivered)
	if delivered == 3 and player.position.distance_to(Vector2(2240, 750)) < 95:
		_end_run(true)
	ui.update_status("PARCELS  %d / 3" % delivered, "HEARTS  %d" % lives)
	queue_redraw()


func _update_guard(index: int, delta: float) -> void:
	var guard: Dictionary = guards[index]
	var sprite: Sprite2D = guard.node
	if guard.stun > 0:
		guard.stun -= delta
		sprite.modulate = Color("9bb8ce")
		guards[index] = guard
		return
	sprite.modulate = Color.WHITE
	var to_player := player.position - sprite.position
	var distance := to_player.length()
	var detection := 105.0 if disguise_time > 0 else 225.0
	var sees: bool = distance < detection and (guard.state == 2 or guard.facing.dot(to_player.normalized()) > 0.30)
	if sees:
		guard.suspicion = minf(1.0, guard.suspicion + delta * (1.45 if disguise_time == 0 else 0.70))
	else:
		guard.suspicion = maxf(0, guard.suspicion - delta * 0.52)
	if guard.suspicion >= 0.85:
		guard.state = 2
	if guard.state == 2 and guard.suspicion < 0.05:
		guard.state = 0
	var target: Vector2 = player.position if guard.state == 2 else guard.home + Vector2(sin(Time.get_ticks_msec() * 0.0007 + guard.phase) * 100, cos(Time.get_ticks_msec() * 0.0009 + guard.phase) * 65)
	var direction := (target - sprite.position).normalized()
	if guard.state == 2 or sprite.position.distance_to(target) > 12:
		sprite.position += direction * (185.0 if guard.state == 2 else 85.0) * delta
		guard.facing = direction
		sprite.frame = (6 if direction.x > 0.45 else 18 if direction.x < -0.45 else 0 if direction.y > 0 else 12) + int(Time.get_ticks_msec() / 80) % 6
	if distance < 43 and guard.state == 2 and player.invulnerable <= 0:
		_caught()
	guards[index] = guard


func _on_player_swung(origin: Vector2, direction: Vector2) -> void:
	if stun_cooldown > 0:
		return
	stun_cooldown = 2.5
	effects.swing(origin, direction)
	_play_sound(preload("res://assets/audio/swing.wav"))
	for index in guards.size():
		var guard: Dictionary = guards[index]
		var sprite: Sprite2D = guard.node
		if sprite.position.distance_to(origin) < 80 and guard.stun <= 0:
			guard.stun = 3.2
			guard.suspicion = 0.0
			guard.state = 0
			guards[index] = guard
			effects.burst(sprite.position, Color("a8d7e0"), 21, 160)
			_play_sound(preload("res://assets/audio/hit.wav"))
			ui.toast("WARDEN DAZED")
			return
	ui.toast("NO WARDEN IN REACH")


func _on_dashed() -> void:
	disguise_time = 0.0
	player.appearance = Color.WHITE
	player.walk_texture = preload("res://assets/hero_walk.png")
	effects.burst(player.position, Color("bde3df"), 18, 175)
	_play_sound(preload("res://assets/audio/dash.wav"))
	for guard in guards:
		if guard.node.position.distance_to(player.position) < 190:
			guard.suspicion = minf(1.0, guard.suspicion + 0.38)


func try_blend() -> void:
	if not playing:
		return
	for crowd in crowds:
		if crowd.node.position.distance_to(player.position) < 86:
			player.appearance = crowd.tint
			player.walk_texture = SHOPPER_TEXTURE
			disguise_time = 18.0
			effects.burst(player.position, Color("e4d1a9"), 19, 100)
			_play_sound(preload("res://assets/audio/build.wav"))
			ui.toast("BORROWED A NEW LOOK")
			return
	ui.toast("GET CLOSE TO A SHOPPER")


func _caught() -> void:
	lives -= 1
	player.invulnerable = 1.5
	player.position = Vector2(maxf(95, player.position.x - 250), 742)
	player.velocity = Vector2.ZERO
	player.appearance = Color.WHITE
	player.walk_texture = preload("res://assets/hero_walk.png")
	disguise_time = 0.0
	effects.burst(player.position, Color("e6a48f"), 27, 160)
	_play_sound(preload("res://assets/audio/damage.wav"))
	ui.toast("SPOTTED! FIND ANOTHER ROUTE")
	if lives <= 0:
		_end_run(false)


func _end_run(won: bool) -> void:
	playing = false
	player.active = false
	player.touch_axis = Vector2.ZERO
	music.stop()
	ui.show_result(won, "The parcels crossed the lantern gate. Your borrowed faces held long enough." if won else "The wardens caught you. Move with the crowd and borrow a new look before crossing their patrols.")


func _play_sound(stream: AudioStream) -> void:
	var sound := sounds[sound_index]
	sound_index = (sound_index + 1) % sounds.size()
	sound.stop()
	sound.stream = stream
	sound.play()


func _draw() -> void:
	for guard in guards:
		if guard.stun > 0:
			continue
		var sprite: Sprite2D = guard.node
		var center := sprite.position
		var facing: Vector2 = guard.facing
		var length := 105.0 if disguise_time > 0 else 225.0
		var left := facing.rotated(-0.70) * length
		var right := facing.rotated(0.70) * length
		var tint := Color("e97c5c", 0.24 if guard.state == 2 else 0.13)
		draw_colored_polygon(PackedVector2Array([center, center + left, center + facing * length, center + right]), tint)
		draw_circle(center + Vector2(0, -36), 5 + guard.suspicion * 7, Color("efbd64") if guard.suspicion < 0.7 else Color("f18464"))
	var gate := Vector2(2240, 750)
	draw_circle(gate, 58, Color("608e79", 0.77) if delivered == 3 else Color("766e66", 0.65))
	draw_arc(gate, 47, 0, TAU, 32, Color("ffe0a1") if delivered == 3 else Color("d6c8a3"), 7)
	for index in 3:
		var dot := gate + Vector2(-22 + index * 22, -5)
		draw_circle(dot, 6, Color("f6df99") if index < delivered else Color("594c40"))
