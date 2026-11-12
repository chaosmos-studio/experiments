extends CharacterBody2D

signal defeated(enemy: CharacterBody2D)

var game: Node2D
var target: Node2D
var sprite: Sprite2D
var health := 3
var heavy := false
var attack_timer := 0.0
var walk_time := 0.0
var hit_flash := 0.0
var facing := Vector2.DOWN
var knockback := Vector2.ZERO


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 2
	var shape := CircleShape2D.new()
	shape.radius = 21.0 if not heavy else 29.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/beetle_walk.png")
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.scale = Vector2(0.60, 0.60) if not heavy else Vector2(0.86, 0.86)
	sprite.position.y = -9.0
	add_child(sprite)
	z_index = 4
	attack_timer = randf_range(0.0, 0.6)


func _draw() -> void:
	draw_circle(Vector2(0, 14), 25.0 if not heavy else 33.0, Color(0.08, 0.09, 0.07, 0.27))
	if heavy and attack_timer < 0.55:
		draw_arc(Vector2.ZERO, 45.0, 0.0, TAU, 32, Color(0.98, 0.54, 0.33, 0.76), 3.0)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or not game.playing:
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	var to_target := target.global_position - global_position
	var dist := to_target.length()
	if dist > 42.0:
		facing = to_target.normalized()
		velocity = velocity.move_toward(facing * (75.0 if heavy else 116.0) + knockback, 500.0 * delta)
		move_and_slide()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		if attack_timer <= 0.0:
			game.damage_hearth(16 if heavy else 7)
			attack_timer = 1.45 if heavy else 1.0
	knockback = knockback.move_toward(Vector2.ZERO, 600.0 * delta)
	var player: CharacterBody2D = game.player
	if global_position.distance_to(player.global_position) < (46.0 if heavy else 35.0) and attack_timer <= 0.0:
		player.take_damage(21 if heavy else 10, global_position)
		attack_timer = 1.0
	walk_time += delta * (6.5 if heavy else 9.0)
	var direction := 0
	if absf(facing.x) > absf(facing.y):
		direction = 1 if facing.x > 0.0 else 3
	elif facing.y < 0.0:
		direction = 2
	sprite.frame = direction * 4 + int(walk_time) % 4
	sprite.modulate = Color(1.0, 0.91, 0.58) if hit_flash > 0.0 else Color.WHITE
	queue_redraw()


func take_hit(amount: int, from: Vector2) -> void:
	health -= amount
	hit_flash = 0.12
	knockback = (global_position - from).normalized() * 300.0
	if health <= 0:
		defeated.emit(self)
