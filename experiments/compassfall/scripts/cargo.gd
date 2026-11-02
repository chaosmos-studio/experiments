class_name CompassCargo
extends RigidBody2D

var gravity_direction: Vector2 = Vector2.DOWN
var glow_time: float = 0.0


func _ready() -> void:
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
	var box: Rect2 = Rect2(-35, -35, 70, 70)
	draw_rect(box.grow(9), Color(0.96, 0.63, 0.18, 0.18 + 0.12 * sin(glow_time * 4.0)), true)
	draw_rect(box, Color("1f6671"), true)
	draw_rect(box, Color("eebf66"), false, 7.0)
	draw_circle(Vector2.ZERO, 18, Color("eebf66"))
	draw_circle(Vector2.ZERO, 10, Color("154651"))
	for corner: Vector2 in [Vector2(-25, -25), Vector2(25, -25), Vector2(-25, 25), Vector2(25, 25)]:
		draw_circle(corner, 3.5, Color("fff4d7"))
