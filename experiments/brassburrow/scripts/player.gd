extends CharacterBody2D

signal swung(origin: Vector2, direction: Vector2)
signal health_changed(value: int)
signal dashed

const WALK_SPEED := 245.0
const ACCELERATION := 1550.0
const FRICTION := 1900.0
const DASH_SPEED := 700.0

var touch_axis := Vector2.ZERO
var facing := Vector2.DOWN
var health := 100
var active := false
var attack_cooldown := 0.0
var dash_cooldown := 0.0
var dash_time := 0.0
var invulnerable := 0.0
var walk_time := 0.0
var attack_time := 0.0
var move_speed_scale := 1.0
var appearance := Color.WHITE
var walk_texture: Texture2D = preload("res://assets/hero_walk.png")
var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 19.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/hero_walk.png")
	sprite.hframes = 6
	sprite.vframes = 4
	sprite.scale = Vector2(0.66, 0.66)
	sprite.position.y = -23.0
	add_child(sprite)
	z_index = 5


func _draw() -> void:
	draw_set_transform(Vector2(0, 14), 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 25.0, Color(0.07, 0.12, 0.08, 0.30))
	draw_set_transform(Vector2.ZERO)


func _physics_process(delta: float) -> void:
	if not active:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	attack_time = maxf(0.0, attack_time - delta)
	var motion := Input.get_vector("move_left", "move_right", "move_up", "move_down") + touch_axis
	motion = motion.limit_length()
	if dash_time > 0.0:
		dash_time -= delta
		velocity = facing * DASH_SPEED
	else:
		var goal := motion * WALK_SPEED * move_speed_scale
		velocity = velocity.move_toward(goal, (ACCELERATION if motion.length() > 0.08 else FRICTION) * delta)
		if motion.length() > 0.08:
			facing = motion.normalized()
	move_and_slide()
	position.x = clampf(position.x, 42.0, 2320.0)
	position.y = clampf(position.y, 80.0, 1440.0)
	_update_sprite(delta)
	if Input.is_action_just_pressed("attack"):
		try_attack()
	if Input.is_action_just_pressed("dash"):
		try_dash()


func _update_sprite(delta: float) -> void:
	var direction := 0
	if absf(facing.x) > absf(facing.y):
		direction = 1 if facing.x > 0.0 else 3
	elif facing.y < 0.0:
		direction = 2
	if velocity.length() > 25.0:
		walk_time += delta * (13.0 if dash_time <= 0.0 else 23.0)
	else:
		walk_time = 0.0
	if attack_time > 0.0:
		sprite.texture = preload("res://assets/hero_attack.png")
		sprite.hframes = 5
		sprite.vframes = 4
		sprite.frame = direction * 5 + clampi(int((0.29 - attack_time) / 0.29 * 5.0), 0, 4)
	else:
		sprite.texture = walk_texture
		sprite.hframes = 6
		sprite.vframes = 4
		sprite.frame = direction * 6 + (int(walk_time) % 6)
	sprite.rotation = clampf(velocity.x / DASH_SPEED * 0.10, -0.10, 0.10)
	sprite.modulate = appearance * (Color(1.0, 0.50, 0.42) if invulnerable > 0.0 and int(invulnerable * 20.0) % 2 == 0 else Color.WHITE)


func try_attack(aim: Vector2 = Vector2.ZERO) -> void:
	if not active or attack_cooldown > 0.0:
		return
	attack_cooldown = 0.29
	attack_time = 0.29
	if aim.length() > 0.1:
		facing = aim.normalized()
	swung.emit(global_position + facing * 31.0, facing)


func try_dash() -> void:
	if not active or dash_cooldown > 0.0:
		return
	dash_time = 0.18
	dash_cooldown = 1.45
	invulnerable = maxf(invulnerable, 0.3)
	dashed.emit()


func take_damage(amount: int, source: Vector2) -> void:
	if not active or invulnerable > 0.0:
		return
	health = maxi(0, health - amount)
	invulnerable = 0.62
	velocity = (global_position - source).normalized() * 300.0
	health_changed.emit(health)
