extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const GroundScript := preload("res://scripts/ground.gd")
const EffectsScript := preload("res://scripts/effects.gd")
const UIScript := preload("res://scripts/ui.gd")
const HEARTH_TEXTURE := preload("res://assets/hearth.png")
const TURRET_TEXTURE := preload("res://assets/turret.png")
const POD_TEXTURE := preload("res://assets/pod.png")
const TREE_TEXTURE := preload("res://assets/tree.png")
const STONE_TEXTURE := preload("res://assets/stone.png")
const SOUNDS := {
	"swing": preload("res://assets/audio/swing.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"harvest": preload("res://assets/audio/harvest.wav"),
	"build": preload("res://assets/audio/build.wav"),
	"shot": preload("res://assets/audio/shot.wav"),
	"damage": preload("res://assets/audio/damage.wav"),
	"dash": preload("res://assets/audio/dash.wav"),
	"repair": preload("res://assets/audio/repair.wav"),
}

var playing := false
var player: CharacterBody2D
var hearth: Node2D
var hearth_sprite: Sprite2D
var actors: Node2D
var effects: Node2D
var ui: CanvasLayer
var camera: Camera2D
var rng := RandomNumberGenerator.new()
var pods: Array[Dictionary] = []
var turrets: Array[Dictionary] = []
var enemies: Array[CharacterBody2D] = []
var run_time := 0.0
var spawn_timer := 0.0
var copper := 5
var hearth_health := 200
var stage := 0
var trauma := 0.0
var sound_players: Array[AudioStreamPlayer] = []
var sound_cursor := 0
var music: AudioStreamPlayer


func _ready() -> void:
	rng.seed = 314159
	_register_input()
	for index in 8:
		var player_node := AudioStreamPlayer.new()
		player_node.volume_db = -8.0
		add_child(player_node)
		sound_players.append(player_node)
	music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/audio/march.ogg")
	music.volume_db = -18.0
	add_child(music)
	music.finished.connect(func() -> void:
		if playing:
			music.play()
	)
	var ground: Node2D = GroundScript.new()
	add_child(ground)
	actors = Node2D.new()
	add_child(actors)
	_spawn_decor()
	hearth = Node2D.new()
	hearth.position = Vector2(230, 742)
	actors.add_child(hearth)
	hearth_sprite = Sprite2D.new()
	hearth_sprite.texture = HEARTH_TEXTURE
	hearth_sprite.scale = Vector2(0.73, 0.73)
	hearth_sprite.position.y = -47
	hearth.add_child(hearth_sprite)
	hearth.z_index = 3
	player = PlayerScript.new()
	player.position = hearth.position + Vector2(76, 68)
	actors.add_child(player)
	player.swung.connect(_on_player_swung)
	player.health_changed.connect(_on_player_health_changed)
	player.dashed.connect(_on_player_dashed)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2380
	camera.limit_bottom = 1500
	player.add_child(camera)
	camera.make_current()
	effects = EffectsScript.new()
	effects.z_index = 20
	add_child(effects)
	_spawn_pods()
	ui = UIScript.new()
	add_child(ui)
	ui.start_requested.connect(start_run)
	ui.attack_requested.connect(func() -> void: player.try_attack())
	ui.dash_requested.connect(func() -> void: player.try_dash())
	ui.build_requested.connect(try_build)
	ui.repair_requested.connect(try_repair)
	ui.touch_axis_changed.connect(func(axis: Vector2) -> void: player.touch_axis = axis)
	ui.update_status(hearth_health, player.health, copper, stage)
	queue_redraw()


func _register_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("attack", [KEY_J])
	_bind("dash", [KEY_SPACE])
	_bind("build", [KEY_K])
	_bind("repair", [KEY_R])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", click)


func _bind(action: StringName, codes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for code in codes:
		var event := InputEventKey.new()
		event.physical_keycode = code
		InputMap.action_add_event(action, event)


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player.try_attack(get_global_mouse_position() - player.global_position)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("build"):
		try_build()
	elif event.is_action_pressed("repair"):
		try_repair()


func _spawn_pods() -> void:
	for i in range(32):
		var pod := Sprite2D.new()
		pod.texture = POD_TEXTURE
		pod.scale = Vector2.ONE * rng.randf_range(0.40, 0.56)
		pod.position = Vector2(300 + i * 64 + rng.randf_range(-35, 35), 740 + rng.randf_range(-280, 290))
		pod.z_index = 2
		actors.add_child(pod)
		pods.append({"node": pod, "health": 2})


func _spawn_decor() -> void:
	for i in 68:
		var x := rng.randf_range(30.0, 2330.0)
		var y := rng.randf_range(50.0, 1450.0)
		if y > 525.0 and y < 960.0:
			continue
		var is_tree := rng.randf() < 0.76
		var prop := StaticBody2D.new()
		prop.position = Vector2(x, y)
		prop.collision_layer = 2
		prop.collision_mask = 0
		var shape := CircleShape2D.new()
		shape.radius = 19.0 if is_tree else 13.0
		var collider := CollisionShape2D.new()
		collider.shape = shape
		prop.add_child(collider)
		var sprite := Sprite2D.new()
		sprite.texture = TREE_TEXTURE if is_tree else STONE_TEXTURE
		sprite.scale = Vector2.ONE * rng.randf_range(0.88, 1.28)
		sprite.position.y = -27.0 if is_tree else -6.0
		if is_tree:
			sprite.modulate = Color("d4dcb5") if x < 810 else Color("b9d2c5") if x < 1640 else Color("9cb5c9")
		prop.add_child(sprite)
		actors.add_child(prop)


func start_run() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	for turret in turrets:
		if is_instance_valid(turret.node):
			turret.node.queue_free()
	turrets.clear()
	for pod in pods:
		if is_instance_valid(pod.node):
			pod.node.queue_free()
	pods.clear()
	_spawn_pods()
	run_time = 0.0
	spawn_timer = 1.5
	copper = 5
	hearth_health = 200
	stage = 0
	trauma = 0.0
	hearth.position = Vector2(230, 742)
	player.position = hearth.position + Vector2(76, 68)
	player.health = 100
	player.active = true
	player.invulnerable = 0.7
	playing = true
	music.play()
	ui.show_play()
	ui.toast("KEEP THE HEARTH MOVING")
	ui.update_status(hearth_health, player.health, copper, stage)


func _process(delta: float) -> void:
	if not playing:
		return
	run_time += delta
	var next_stage := mini(2, int(run_time / 34.0))
	if next_stage != stage:
		stage = next_stage
		ui.toast("THE PATH GETS ROUGHER")
		effects.burst(hearth.position, Color("f6c66e"), 28, 190.0)
	hearth.position.x = minf(2220.0, 230.0 + run_time * 16.0)
	hearth.position.y = 742.0 + sin(hearth.position.x * 0.006) * 27.0
	hearth_sprite.position.y = -47.0 + sin(run_time * 5.0) * 2.5
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = [2.55, 1.85, 1.30][stage] * rng.randf_range(0.75, 1.27)
	for turret in turrets:
		turret.timer -= delta
		if turret.timer <= 0.0:
			_fire_turret(turret)
			turret.timer = 0.74
	trauma = maxf(0.0, trauma - delta * 1.65)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * trauma * trauma * 18.0
	ui.update_status(hearth_health, player.health, copper, stage)
	if run_time >= 102.0:
		_end_run(true)


func _spawn_enemy() -> void:
	var enemy: CharacterBody2D = EnemyScript.new()
	enemy.game = self
	enemy.target = hearth
	enemy.heavy = stage > 0 and rng.randi_range(0, 5) == 0
	enemy.health = 8 if enemy.heavy else 3 + stage
	enemy.position = hearth.position + Vector2(rng.randf_range(360.0, 560.0), rng.randf_range(-320.0, 320.0))
	enemy.position.x = minf(2320.0, enemy.position.x)
	enemy.position.y = clampf(enemy.position.y, 100.0, 1390.0)
	actors.add_child(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	enemies.append(enemy)
	if enemy.heavy:
		ui.toast("ARMORED BEETLE AHEAD")


func _on_player_swung(origin: Vector2, direction: Vector2) -> void:
	effects.swing(origin, direction)
	_play_sound("swing")
	var impact := false
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - origin
		if to_enemy.length() < 76.0 and direction.dot(to_enemy.normalized()) > -0.20:
			enemy.take_hit(2, player.global_position)
			effects.burst(enemy.global_position, Color("f7b46b"), 10, 160.0)
			impact = true
	for index in range(pods.size() - 1, -1, -1):
		var pod: Dictionary = pods[index]
		var node: Sprite2D = pod.node
		var to_pod := node.global_position - origin
		if to_pod.length() < 78.0 and direction.dot(to_pod.normalized()) > -0.20:
			pod.health -= 1
			pods[index] = pod
			node.modulate = Color("ffdda1")
			var tween := create_tween()
			tween.tween_property(node, "modulate", Color.WHITE, 0.23)
			effects.burst(node.global_position, Color("eeb65d"), 9, 120.0)
			impact = true
			if pod.health <= 0:
				pods.remove_at(index)
				copper += 3
				effects.burst(node.global_position, Color("ffe6a3"), 20, 210.0)
				node.queue_free()
				ui.toast("+3 COPPER")
	if impact:
		_play_sound("hit")
		trauma = minf(1.0, trauma + 0.18)


func _on_player_dashed() -> void:
	effects.burst(player.global_position, Color("bbefc1"), 17, 175.0)
	_play_sound("dash")


func _on_player_health_changed(value: int) -> void:
	_play_sound("damage")
	trauma = minf(1.0, trauma + 0.31)
	effects.burst(player.global_position, Color("f39277"), 18, 145.0)
	if value <= 0:
		player.health = 100
		player.position = hearth.position + Vector2(52, 60)
		player.invulnerable = 1.7
		damage_hearth(24)
		ui.toast("PIP IS BACK · THE HEARTH PAID")
	ui.update_status(hearth_health, player.health, copper, stage)


func _on_enemy_defeated(enemy: CharacterBody2D) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	_play_sound("harvest")
	copper += 1
	effects.burst(enemy.global_position, Color("f6d58c"), 22, 230.0)
	trauma = minf(1.0, trauma + (0.4 if enemy.heavy else 0.19))
	enemy.queue_free()


func try_build() -> void:
	if not playing:
		return
	if copper < 5:
		ui.toast("NEED 5 COPPER")
		return
	var spot: Vector2 = player.global_position + player.facing * 74.0
	if spot.distance_to(hearth.position) > 380.0:
		ui.toast("BUILD CLOSER TO THE HEARTH")
		return
	for turret in turrets:
		if turret.node.global_position.distance_to(spot) < 88.0:
			ui.toast("TOO CLOSE TO ANOTHER CANNON")
			return
	var node := Sprite2D.new()
	node.texture = TURRET_TEXTURE
	node.scale = Vector2.ONE * 0.56
	node.position = spot
	node.z_index = 3
	actors.add_child(node)
	turrets.append({"node": node, "timer": 0.5})
	_play_sound("build")
	copper -= 5
	effects.burst(spot, Color("d3f1a2"), 30, 170.0)
	ui.toast("SEED CANNON BUILT")


func _fire_turret(turret: Dictionary) -> void:
	var source: Sprite2D = turret.node
	var nearest: CharacterBody2D
	var distance := 270.0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var d := source.global_position.distance_to(enemy.global_position)
		if d < distance:
			distance = d
			nearest = enemy
	if nearest == null:
		return
	source.rotation = source.global_position.angle_to_point(nearest.global_position) + PI / 2.0
	effects.ray(source.global_position, nearest.global_position)
	_play_sound("shot")
	nearest.take_hit(1, source.global_position)


func try_repair() -> void:
	if not playing:
		return
	if hearth_health >= 200:
		ui.toast("THE HEARTH IS WHOLE")
		return
	if copper < 3:
		ui.toast("NEED 3 COPPER")
		return
	if player.global_position.distance_to(hearth.position) > 170.0:
		ui.toast("GET CLOSER TO THE HEARTH")
		return
	copper -= 3
	_play_sound("repair")
	hearth_health = mini(200, hearth_health + 30)
	effects.burst(hearth.position, Color("9de7b0"), 24, 170.0)
	ui.toast("HEARTH PATCHED")


func damage_hearth(amount: int) -> void:
	if not playing:
		return
	hearth_health = maxi(0, hearth_health - amount)
	_play_sound("damage")
	trauma = minf(1.0, trauma + 0.30)
	effects.burst(hearth.position + Vector2(randf_range(-28, 28), -30), Color("ffa36e"), 15, 175.0)
	hearth_sprite.modulate = Color("ff846d")
	var tween := create_tween()
	tween.tween_property(hearth_sprite, "modulate", Color.WHITE, 0.23)
	if hearth_health <= 0:
		_end_run(false)


func _end_run(won: bool) -> void:
	playing = false
	music.stop()
	player.active = false
	player.touch_axis = Vector2.ZERO
	camera.offset = Vector2.ZERO
	var summary := "You marched the hearth through every beetle wave.\nCopper, courage and seed cannons carried it home." if won else "The beetles broke through.\nBuild early, harvest pods and keep close enough to patch the hearth."
	ui.show_result(won, summary)


func _play_sound(name: String) -> void:
	var sound := sound_players[sound_cursor]
	sound_cursor = (sound_cursor + 1) % sound_players.size()
	sound.stop()
	sound.stream = SOUNDS[name]
	sound.play()
