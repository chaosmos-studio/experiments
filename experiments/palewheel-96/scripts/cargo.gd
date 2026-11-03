class_name PalewheelCargo
extends RigidBody2D

const CASE_TEXTURE: Texture2D = preload("res://assets/art/retro_cargo.png")

var gravity_direction: Vector2 = Vector2.DOWN
var glow_time: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gravity_scale = 0.0
	mass = 3.0
	linear_damp = 1.5
	angular_damp = 5.0
	lock_rotation = true
	collision_layer = 4
	collision_mask = 3
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(68, 68)
	shape.shape = box
	add_child(shape)
	can_sleep = false
	queue_redraw()


func _physics_process(delta: float) -> void:
	apply_central_force(gravity_direction * 1050.0 * mass)
	glow_time += delta
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 47.0, Color(0.96, 0.63, 0.18, 0.12 + 0.08 * sin(glow_time * 4.0)))
	draw_texture_rect(CASE_TEXTURE, Rect2(-43, -41, 86, 82), false)
