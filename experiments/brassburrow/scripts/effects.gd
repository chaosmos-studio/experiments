extends Node2D

var particles: Array[Dictionary] = []
var slashes: Array[Dictionary] = []
var rays: Array[Dictionary] = []


func burst(at: Vector2, color: Color, count: int = 12, speed: float = 160.0) -> void:
	for i in count:
		var angle := randf() * TAU
		var velocity := Vector2.from_angle(angle) * randf_range(speed * 0.35, speed)
		particles.append({"position": at, "velocity": velocity, "life": randf_range(0.25, 0.62), "max_life": 0.62, "color": color, "size": randf_range(2.0, 5.0)})
	queue_redraw()


func swing(at: Vector2, direction: Vector2) -> void:
	slashes.append({"position": at, "angle": direction.angle(), "life": 0.19})
	burst(at + direction * 22.0, Color("ffe3a1"), 5, 125.0)


func ray(start: Vector2, end: Vector2) -> void:
	rays.append({"start": start, "end": end, "life": 0.14})
	burst(end, Color("ffcf71"), 4, 95.0)


func _process(delta: float) -> void:
	for particle in particles:
		particle.position += particle.velocity * delta
		particle.velocity = particle.velocity.move_toward(Vector2.ZERO, 180.0 * delta)
		particle.life -= delta
	particles = particles.filter(func(particle: Dictionary) -> bool: return particle.life > 0.0)
	for slash in slashes:
		slash.life -= delta
	slashes = slashes.filter(func(slash: Dictionary) -> bool: return slash.life > 0.0)
	for ray_item in rays:
		ray_item.life -= delta
	rays = rays.filter(func(ray_item: Dictionary) -> bool: return ray_item.life > 0.0)
	if not particles.is_empty() or not slashes.is_empty() or not rays.is_empty():
		queue_redraw()


func _draw() -> void:
	for particle in particles:
		var color: Color = particle.color
		color.a *= clampf(particle.life / particle.max_life, 0.0, 1.0)
		draw_circle(particle.position, particle.size, color)
	for slash in slashes:
		var start: float = slash.angle - 0.9
		var end: float = slash.angle + 0.9
		var alpha: float = slash.life / 0.19
		draw_arc(slash.position, 58.0, start, end, 16, Color(1.0, 0.90, 0.56, alpha), 9.0 * alpha)
	for ray_item in rays:
		var alpha: float = ray_item.life / 0.14
		draw_line(ray_item.start, ray_item.end, Color(1.0, 0.76, 0.34, alpha), 7.0 * alpha)
		draw_line(ray_item.start, ray_item.end, Color(1.0, 0.98, 0.75, alpha), 2.0 * alpha)
