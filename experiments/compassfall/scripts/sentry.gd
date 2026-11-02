class_name CompassSentry
extends Area2D

const SPRITE: Texture2D = preload("res://assets/sprites/sentry.png")

var start_point: Vector2
var end_point: Vector2
var period: float = 3.0
var phase_offset: float = 0.0
var elapsed: float = 0.0
var freeze_remaining: float = 0.0
var active: bool = false
var sprite: Sprite2D


func configure(data: Dictionary) -> void:
	start_point = data["from"]
	end_point = data["to"]
	period = data["period"]
	phase_offset = data["offset"]
	position = start_point.lerp(end_point, 0.5 + 0.5 * sin(phase_offset))


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 39.0
	shape.shape = circle
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = SPRITE
	sprite.scale = Vector2(0.43, 0.43)
	add_child(sprite)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active:
		return
	if freeze_remaining > 0.0:
		freeze_remaining = maxf(0.0, freeze_remaining - delta)
		if freeze_remaining == 0.0:
			set_deferred("monitoring", true)
	else:
		elapsed += delta
		position = start_point.lerp(end_point, 0.5 + 0.5 * sin(elapsed * TAU / period + phase_offset))
	sprite.rotation += delta * (0.6 if freeze_remaining > 0.0 else 1.8)
	sprite.modulate = Color("bde9dc") if freeze_remaining > 0.0 else Color.WHITE
	queue_redraw()


func freeze_for(seconds: float) -> void:
	freeze_remaining = maxf(freeze_remaining, seconds)
	set_deferred("monitoring", false)
	queue_redraw()


func _draw() -> void:
	var color: Color = Color("68cdbd") if freeze_remaining > 0.0 else Color("f5a467")
	draw_circle(Vector2.ZERO, 57.0, Color(color, 0.11))
	draw_arc(Vector2.ZERO, 50.0, 0.0, TAU, 40, Color(color, 0.35), 4.0, true)
