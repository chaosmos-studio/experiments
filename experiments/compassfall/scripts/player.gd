class_name CompassPilot
extends CharacterBody2D

signal jumped
signal landed

const RUN_SPEED: float = 360.0
const RUN_ACCEL: float = 1850.0
const AIR_ACCEL: float = 1180.0
const JUMP_SPEED: float = 535.0
const GRAVITY: float = 1190.0
const COYOTE_TIME: float = 0.11
const JUMP_BUFFER: float = 0.13

var gravity_direction: Vector2 = Vector2.DOWN
var touch_axis: float = 0.0
var touch_jump: bool = false
var control_enabled: bool = true
var coyote: float = 0.0
var jump_buffer: float = 0.0
var was_grounded: bool = false
var facing: float = 1.0
var sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 5
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 12.0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 25.0
	capsule.height = 78.0
	shape.shape = capsule
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(0.53, 0.53)
	sprite.position = Vector2(0, -5)
	sprite.z_index = 5
	sprite.sprite_frames = _build_frames()
	add_child(sprite)
	sprite.play("idle")
	up_direction = -gravity_direction


func _build_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	for animation: String in ["idle", "run", "float"]:
		frames.add_animation(animation)
		frames.set_animation_loop(animation, true)
		frames.set_animation_speed(animation, 7.0 if animation == "idle" else 12.0)
		var count: int = 6 if animation == "idle" else (8 if animation == "run" else 4)
		for index: int in range(count):
			var path: String = "res://assets/sprites/pilot_%s_%02d.png" % [animation, index]
			frames.add_frame(animation, load(path) as Texture2D)
	return frames


func _physics_process(delta: float) -> void:
	if not control_enabled:
		return
	var grounded: bool = is_on_floor()
	coyote = COYOTE_TIME if grounded else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump") or touch_jump:
		jump_buffer = JUMP_BUFFER
		touch_jump = false
	var axis: float = Input.get_axis("move_left", "move_right")
	if absf(touch_axis) > absf(axis):
		axis = touch_axis
	var tangent: Vector2 = Vector2(gravity_direction.y, -gravity_direction.x)
	var along: float = velocity.dot(tangent)
	var falling: float = minf(velocity.dot(gravity_direction) + GRAVITY * delta, 850.0)
	along = move_toward(along, axis * RUN_SPEED, (RUN_ACCEL if grounded else AIR_ACCEL) * delta)
	if jump_buffer > 0.0 and coyote > 0.0:
		falling = -JUMP_SPEED
		coyote = 0.0
		jump_buffer = 0.0
		jumped.emit()
	velocity = tangent * along + gravity_direction * falling
	move_and_slide()
	if not grounded and is_on_floor():
		landed.emit()
	if absf(axis) > 0.1:
		facing = signf(axis)
	sprite.flip_h = facing < 0.0
	var animation: String = "float"
	if is_on_floor():
		animation = "run" if absf(along) > 45.0 else "idle"
	if sprite.animation != animation:
		sprite.play(animation)
	was_grounded = is_on_floor()


func set_gravity_direction(direction: Vector2) -> void:
	gravity_direction = direction
	up_direction = -direction
	var visual_rotation: float = sprite.global_rotation
	rotation = direction.angle() - PI * 0.5
	sprite.global_rotation = visual_rotation
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	coyote = 0.0
	velocity += direction * 110.0


func queue_touch_jump() -> void:
	touch_jump = true
