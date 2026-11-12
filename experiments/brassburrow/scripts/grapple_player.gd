extends CharacterBody2D

signal dashed
signal hook_changed(attached: bool)

const HERO_TEXTURE := preload("res://assets/hero_walk.png")

var active := false
var touch_axis := Vector2.ZERO
var facing := Vector2.RIGHT
var hook: Node2D
var rope_length := 260.0
var reeling := false
var dash_cooldown := 0.0
var invulnerable := 0.0
var walk_time := 0.0
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
	sprite.texture = HERO_TEXTURE
	sprite.hframes = 6
	sprite.vframes = 4
	sprite.scale = Vector2.ONE * 0.67
	sprite.position.y = -23
	add_child(sprite)
	z_index = 6


func _physics_process(delta: float) -> void:
	if not active:
		return
	dash_cooldown = maxf(0, dash_cooldown - delta)
	invulnerable = maxf(0, invulnerable - delta)
	var input := (Input.get_vector("move_left", "move_right", "move_up", "move_down") + touch_axis).limit_length()
	if input.length() > 0.1:
		facing = input.normalized()
	velocity += input * 930.0 * delta
	velocity *= pow(0.986, delta * 60.0)
	if is_instance_valid(hook):
		var vector := hook.global_position - global_position
		var distance := vector.length()
		if reeling:
			rope_length = maxf(78.0, rope_length - delta * 250.0)
		if distance > rope_length:
			var pull := vector.normalized()
			velocity += pull * (distance - rope_length) * 16.0 * delta
			var outward := velocity.dot(-pull)
			if outward > 0:
				velocity += pull * outward * minf(1.0, delta * 9.0)
	velocity = velocity.limit_length(880.0)
	move_and_slide()
	position.x = clampf(position.x, 44, 2540)
	position.y = clampf(position.y, 70, 1420)
	_update_sprite(delta)
	queue_redraw()
	if Input.is_action_just_pressed("hook"):
		hook_changed.emit(is_instance_valid(hook))
	if Input.is_action_just_pressed("dash"):
		try_dash()


func _update_sprite(delta: float) -> void:
	var direction := 0
	if absf(facing.x) > absf(facing.y):
		direction = 1 if facing.x > 0 else 3
	elif facing.y < 0:
		direction = 2
	walk_time += delta * clampf(velocity.length() / 31.0, 3.0, 19.0)
	sprite.frame = direction * 6 + int(walk_time) % 6
	sprite.rotation = clampf(velocity.x / 950.0 * 0.24, -0.24, 0.24)
	sprite.modulate = Color(1, 0.48, 0.4) if invulnerable > 0 and int(invulnerable * 20) % 2 == 0 else Color.WHITE


func try_dash() -> void:
	if not active or dash_cooldown > 0:
		return
	dash_cooldown = 1.05
	velocity += facing * 495.0
	invulnerable = maxf(invulnerable, 0.25)
	dashed.emit()


func attach(anchor: Node2D) -> void:
	hook = anchor
	rope_length = minf(310.0, global_position.distance_to(anchor.global_position) * 0.86)
	queue_redraw()


func release() -> void:
	hook = null
	reeling = false
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 13), 24, Color(0.06, 0.13, 0.14, 0.29))
	if not is_instance_valid(hook):
		return
	var target := to_local(hook.global_position)
	var middle := target * 0.52 + Vector2(-target.y, target.x).normalized() * sin(Time.get_ticks_msec() * 0.012) * 4.0
	draw_polyline(PackedVector2Array([Vector2.ZERO, middle, target]), Color("4a3b2b"), 5, true)
	draw_polyline(PackedVector2Array([Vector2.ZERO, middle, target]), Color("efc76d"), 2, true)
	draw_circle(target, 10, Color("f6dd9f"))
