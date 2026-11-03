class_name PalewheelCourier
extends CharacterBody2D

signal jumped
signal landed
signal stepped

const RUN_SPEED: float = 360.0
const RUN_ACCEL: float = 1850.0
const AIR_ACCEL: float = 820.0
const JUMP_SPEED: float = 590.0
const GRAVITY: float = 1550.0
const COYOTE_TIME: float = 0.11
const JUMP_BUFFER: float = 0.13

var gravity_direction: Vector2 = Vector2.DOWN
var touch_axis: float = 0.0
var touch_jump: bool = false
var touch_crouch: bool = false
var crouching: bool = false
var jump_cut_requested: bool = false
var control_enabled: bool = true
var coyote: float = 0.0
var jump_buffer: float = 0.0
var facing: float = 1.0
var sprite: AnimatedSprite2D
var takeoff_time: float = 0.0
var landing_time: float = 0.0
var shift_time: float = 0.0
var step_age: float = 0.0
var rotation_tween: Tween
var collision_shape: CollisionShape2D
var capsule: CapsuleShape2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 5
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 12.0
	collision_shape = CollisionShape2D.new()
	capsule = CapsuleShape2D.new()
	capsule.radius = 25.0
	capsule.height = 78.0
	collision_shape.shape = capsule
	add_child(collision_shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_frames()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.25, 1.25)
	sprite.position = Vector2(0, -17)
	sprite.z_index = 5
	add_child(sprite)
	sprite.frame_changed.connect(_on_sprite_frame_changed)
	sprite.play("idle")
	up_direction = -gravity_direction


func _build_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	for animation: String in ["idle", "run", "crouch", "takeoff", "rise", "apex", "fall", "land", "shift"]:
		frames.add_animation(animation)
		frames.set_animation_loop(animation, animation == "idle" or animation == "run")
		frames.set_animation_speed(animation, 12.0 if animation == "run" else 8.0)
	frames.add_frame("idle", preload("res://assets/art/retro_idle.png"))
	for index: int in range(8):
		frames.add_frame("run", load("res://assets/art/retro_run_%02d.png" % index) as Texture2D)
	frames.add_frame("crouch", preload("res://assets/art/retro_crouch.png"))
	frames.add_frame("takeoff", preload("res://assets/art/retro_crouch.png"))
	frames.add_frame("takeoff", preload("res://assets/art/retro_jump.png"))
	frames.add_frame("rise", preload("res://assets/art/retro_jump.png"))
	frames.add_frame("apex", preload("res://assets/art/retro_jump.png"))
	frames.add_frame("fall", preload("res://assets/art/retro_jump.png"))
	frames.add_frame("land", preload("res://assets/art/retro_crouch.png"))
	frames.add_frame("land", preload("res://assets/art/retro_idle.png"))
	frames.add_frame("shift", preload("res://assets/art/retro_shift.png"))
	return frames


func _process(delta: float) -> void:
	var had_step: bool = step_age > 0.0
	step_age = maxf(0.0, step_age - delta)
	if had_step:
		queue_redraw()


func _draw() -> void:
	if step_age <= 0.0:
		return
	var progress: float = 1.0 - step_age / 0.2
	var opacity: float = (1.0 - progress) * 0.55
	for side: float in [-1.0, 1.0]:
		var origin: Vector2 = Vector2(side * (13.0 + progress * 17.0), 39.0 - progress * 6.0)
		draw_arc(origin, 5.0 + progress * 13.0, PI, TAU, 12, Color(0.82, 0.87, 0.87, opacity), 3.0, true)
		draw_circle(origin + Vector2(side * 12.0, -7.0 - progress * 14.0), 2.5, Color(0.86, 0.92, 0.91, opacity))


func _on_sprite_frame_changed() -> void:
	if sprite.animation == "run" and (sprite.frame == 0 or sprite.frame == 4) and control_enabled and is_on_floor():
		step_age = 0.2
		stepped.emit()


func _physics_process(delta: float) -> void:
	if not control_enabled:
		return
	_set_crouch(Input.is_action_pressed("crouch") or touch_crouch)
	var grounded: bool = is_on_floor()
	coyote = COYOTE_TIME if grounded else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump") or touch_jump:
		jump_buffer = JUMP_BUFFER
		touch_jump = false
	if crouching:
		jump_buffer = 0.0
	var axis: float = Input.get_axis("move_left", "move_right")
	if absf(touch_axis) > absf(axis):
		axis = touch_axis
	var tangent: Vector2 = Vector2(gravity_direction.y, -gravity_direction.x)
	var along: float = velocity.dot(tangent)
	var falling: float = minf(velocity.dot(gravity_direction) + GRAVITY * delta, 900.0)
	var target_speed: float = 115.0 if crouching else RUN_SPEED
	along = move_toward(along, axis * target_speed, (RUN_ACCEL if grounded else AIR_ACCEL) * delta)
	if jump_buffer > 0.0 and coyote > 0.0:
		falling = -JUMP_SPEED
		coyote = 0.0
		jump_buffer = 0.0
		takeoff_time = 0.14
		landing_time = 0.0
		jumped.emit()
	if jump_cut_requested or Input.is_action_just_released("jump"):
		if falling < -JUMP_SPEED * 0.48:
			falling = -JUMP_SPEED * 0.48
		jump_cut_requested = false
	velocity = tangent * along + gravity_direction * falling
	move_and_slide()
	if not grounded and is_on_floor():
		landing_time = 0.17
		takeoff_time = 0.0
		step_age = 0.2
		landed.emit()
	takeoff_time = maxf(0.0, takeoff_time - delta)
	landing_time = maxf(0.0, landing_time - delta)
	shift_time = maxf(0.0, shift_time - delta)
	if absf(axis) > 0.1:
		facing = signf(axis)
	sprite.flip_h = facing < 0.0
	var animation: String = "idle"
	if shift_time > 0.0:
		animation = "shift"
	elif crouching:
		animation = "crouch"
	elif landing_time > 0.0:
		animation = "land"
	elif takeoff_time > 0.0:
		animation = "takeoff"
	elif not is_on_floor():
		var vertical_speed: float = velocity.dot(gravity_direction)
		animation = "rise" if vertical_speed < -130.0 else "apex" if vertical_speed < 110.0 else "fall"
	elif absf(along) > 45.0:
		animation = "run"
	if sprite.animation != animation:
		sprite.play(animation)


func set_gravity_direction(direction: Vector2) -> void:
	if gravity_direction != direction:
		shift_time = 0.23
		var visual_angle: float = sprite.global_rotation
		if rotation_tween and rotation_tween.is_running():
			rotation_tween.kill()
		rotation = direction.angle() - PI * 0.5
		sprite.rotation = wrapf(visual_angle - rotation, -PI, PI)
		rotation_tween = create_tween()
		rotation_tween.tween_property(sprite, "rotation", 0.0, 0.23).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	gravity_direction = direction
	up_direction = -direction
	coyote = 0.0


func queue_touch_jump() -> void:
	touch_jump = true


func release_touch_jump() -> void:
	jump_cut_requested = true


func set_touch_crouch(value: bool) -> void:
	touch_crouch = value


func _set_crouch(requested: bool) -> void:
	if requested == crouching or (not requested and not _can_stand()):
		return
	crouching = requested
	capsule.radius = 21.0 if requested else 25.0
	capsule.height = 52.0 if requested else 78.0
	collision_shape.position = Vector2(0, 13) if requested else Vector2.ZERO
	if requested:
		step_age = 0.15


func _can_stand() -> bool:
	var standing: CapsuleShape2D = CapsuleShape2D.new()
	standing.radius = 25.0
	standing.height = 78.0
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = standing
	query.transform = global_transform
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
