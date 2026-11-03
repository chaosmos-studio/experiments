class_name PalewheelWorldView
extends Node2D

const BACKDROPS: Array = [
	preload("res://assets/art/retro_engine_a.png"),
	preload("res://assets/art/retro_engine_b.png"),
]
const AIRLOCK_CLOSED: Texture2D = preload("res://assets/art/retro_gate_closed.png")
const AIRLOCK_OPEN: Texture2D = preload("res://assets/art/retro_gate_open.png")
const LIGHT_CELL: Texture2D = preload("res://assets/art/retro_cell.png")
const BEACON: Texture2D = preload("res://assets/art/retro_beacon.png")
const EXHAUST_VENT: Texture2D = preload("res://assets/art/retro_vent.png")
const CELL_OFFSETS: Array[float] = [0.0, -1.0, -2.0, -3.0, -3.0, -2.0, -1.0, 0.0]
const INK: Color = Color("17142b")
const BRASS: Color = Color("eaa250")
const PORCELAIN: Color = Color("ffe7ad")

var level: Dictionary = {}
var phase: int = 0
var collected: Array[bool] = []
var pad_armed: bool = false
var checkpoint_active: bool = false
var door_open: bool = false
var time: float = 0.0
var gravity_direction: Vector2 = Vector2.DOWN
var shift_origin: Vector2 = Vector2.ZERO
var shift_age: float = 1.0
var door_progress: float = 0.0
var spark_bursts: Array[Dictionary] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	time += delta
	shift_age += delta
	door_progress = move_toward(door_progress, 1.0 if door_open else 0.0, delta * 3.5)
	for index: int in range(spark_bursts.size() - 1, -1, -1):
		spark_bursts[index]["age"] += delta
		if spark_bursts[index]["age"] > 0.48:
			spark_bursts.remove_at(index)
	queue_redraw()


func _draw() -> void:
	var backdrop_index: int = clampi(int(level.get("backdrop", 0)), 0, BACKDROPS.size() - 1)
	draw_texture_rect(BACKDROPS[backdrop_index] as Texture2D, Rect2(-330, -180, 2580, 1440), false)
	draw_rect(Rect2(-330, -180, 2580, 1440), Color("100d22", 0.1))
	if level.is_empty():
		return
	_draw_chamber()
	for wall: Rect2 in level["walls"]:
		_draw_wall(wall)
	for bridge: Rect2 in level["phase_walls"]:
		_draw_bridge(bridge)
	_draw_sentry_tracks()
	for hazard: Rect2 in level["hazards"]:
		_draw_hazard(hazard)
	for index: int in range(collected.size()):
		if not collected[index]:
			_draw_shard(level["shards"][index], index)
	if level["pad"] != Vector2.ZERO:
		_draw_pad(level["pad"])
	if level["checkpoint"] != Vector2.ZERO:
		_draw_checkpoint(level["checkpoint"])
	_draw_door(level["exit"])
	_draw_motes()
	_draw_spark_bursts()
	if shift_age < 0.62:
		var radius: float = 36.0 + shift_age * 710.0
		var opacity: float = (0.62 - shift_age) / 0.62
		draw_arc(shift_origin, radius, 0.0, TAU, 32, Color(0.95, 0.69, 0.26, opacity * 0.8), 10.0, true)
		draw_arc(shift_origin, radius + 26.0, 0.0, TAU, 32, Color(0.26, 0.85, 0.84, opacity * 0.5), 4.0, true)


func _draw_chamber() -> void:
	draw_rect(Rect2(110, 168, 1700, 760), Color("17142b", 0.09))


func _draw_wall(wall: Rect2) -> void:
	draw_rect(wall.grow(6.0), Color("100c20", 0.7))
	draw_rect(wall.grow(2.0), INK)
	draw_rect(wall.grow(-3.0), Color("764a54"))
	var inset: Rect2 = wall.grow(-8.0)
	if inset.size.x > 0.0 and inset.size.y > 0.0:
		draw_rect(inset, Color("bb7b55"))
		if wall.size.x >= wall.size.y:
			draw_line(inset.position + Vector2(5, 4), Vector2(inset.end.x - 5, inset.position.y + 4), PORCELAIN, 3.0)
			draw_line(Vector2(inset.position.x, inset.end.y - 4), Vector2(inset.end.x, inset.end.y - 4), Color("4c2b44"), 3.0)
		else:
			draw_line(inset.position + Vector2(4, 5), Vector2(inset.position.x + 4, inset.end.y - 5), PORCELAIN, 3.0)
	if wall.size.x > wall.size.y:
		for x: float in range(int(wall.position.x + 24), int(wall.end.x - 8), 78):
			draw_line(Vector2(x, inset.position.y + 4), Vector2(x - 7, inset.end.y - 4), Color("603950", 0.8), 2.0)
			draw_circle(Vector2(x + 22, wall.get_center().y), 4.0, INK)
			draw_circle(Vector2(x + 22, wall.get_center().y), 2.0, BRASS)
			draw_line(Vector2(x + 37, wall.position.y + 6), Vector2(x + 51, wall.position.y + 6), BRASS, 3.0)
	else:
		for y: float in range(int(wall.position.y + 26), int(wall.end.y - 8), 78):
			draw_line(Vector2(inset.position.x + 4, y), Vector2(inset.end.x - 4, y - 7), Color("603950", 0.8), 2.0)
			draw_circle(Vector2(wall.get_center().x, y + 22), 4.0, INK)
			draw_circle(Vector2(wall.get_center().x, y + 22), 2.0, BRASS)


func _draw_bridge(bridge: Rect2) -> void:
	var enabled: bool = phase == 1
	var opacity: float = 0.9 if enabled else 0.25
	draw_rect(bridge.grow(11.0), Color(0.95, 0.69, 0.26, 0.15 if enabled else 0.04))
	draw_rect(bridge.grow(2.0), Color("2f2848", opacity))
	draw_rect(bridge.grow(-4.0), Color("eaa250", opacity))
	for x: float in range(int(bridge.position.x + 13), int(bridge.end.x), 34):
		draw_line(Vector2(x, bridge.position.y + 4), Vector2(x - 11, bridge.end.y - 4), Color(1.0, 1.0, 1.0, opacity), 3.0)


func _draw_hazard(area: Rect2) -> void:
	draw_rect(area.grow(7.0), Color("f8a548", 0.15))
	draw_texture_rect(EXHAUST_VENT, Rect2(area.position + Vector2(-7, -46), Vector2(area.size.x + 14, 75)), false)


func _draw_sentry_tracks() -> void:
	for data: Dictionary in level["sentries"]:
		var from: Vector2 = data["from"]
		var to: Vector2 = data["to"]
		draw_line(from, to, Color("eaa250", 0.75), 8.0)
		draw_line(from, to, INK, 3.0)
		draw_circle(from, 8.0, INK)
		draw_circle(to, 8.0, INK)


func _draw_checkpoint(pos: Vector2) -> void:
	var color: Color = Color("56d6cf", 0.22) if checkpoint_active else Color("17142b", 0.14)
	draw_circle(pos + Vector2(0, 6), 53.0, color)
	draw_texture_rect(BEACON, Rect2(pos + Vector2(-49, -65), Vector2(98, 140)), false, Color.WHITE if checkpoint_active else Color("77858a"))


func _draw_shard(point: Vector2, index: int) -> void:
	var frame: int = int(time * 6.0 + float(index) * 2.0) % 8
	var offset: float = CELL_OFFSETS[frame]
	var pos: Vector2 = point + Vector2(0, offset)
	draw_circle(pos, 49.0, Color("ffc879", 0.14))
	draw_texture_rect(LIGHT_CELL, Rect2(pos - Vector2(39, 43), Vector2(78, 86)), false)


func _draw_pad(pos: Vector2) -> void:
	var color: Color = Color("56d6cf") if pad_armed else Color("bb7b55")
	draw_rect(Rect2(pos.x - 58, pos.y - 8, 116, 24), INK)
	draw_rect(Rect2(pos.x - 48, pos.y - 17, 96, 18), color)
	draw_line(pos + Vector2(-34, -11), pos + Vector2(34, -11), Color("ffffff"), 3.0)
	for x: float in [-28.0, 0.0, 28.0]:
		draw_circle(pos + Vector2(x, -8), 4.0, BRASS)


func _draw_door(pos: Vector2) -> void:
	var rect: Rect2 = Rect2(pos - Vector2(93, 93), Vector2(186, 186))
	if door_progress > 0.0:
		draw_circle(pos, 88.0, Color("56d6cf", door_progress * 0.18))
	draw_texture_rect(AIRLOCK_CLOSED, rect, false, Color(1.0, 1.0, 1.0, 1.0 - door_progress))
	if door_progress > 0.0:
		draw_texture_rect(AIRLOCK_OPEN, rect, false, Color(1.0, 1.0, 1.0, door_progress))


func collect_spark(pos: Vector2) -> void:
	spark_bursts.append({"position": pos, "age": 0.0})


func _draw_spark_bursts() -> void:
	for burst: Dictionary in spark_bursts:
		var age: float = burst["age"]
		var center: Vector2 = burst["position"]
		var reach: float = 20.0 + age * 170.0
		var fade: float = 1.0 - age / 0.48
		for index: int in range(10):
			var ray: Vector2 = Vector2.RIGHT.rotated(float(index) * TAU / 10.0)
			draw_line(center + ray * (reach - 13.0), center + ray * reach, Color(0.89, 1.0, 1.0, fade), 3.0 * fade)


func _draw_motes() -> void:
	var backdrop_index: int = int(level.get("backdrop", 0))
	var mote_color: Color = Color(0.95, 0.70, 0.3, 0.3)
	var drift: Vector2 = Vector2(11.0, -3.0)
	if backdrop_index == 4:
		mote_color = Color(0.74, 0.95, 0.96, 0.29)
		drift = Vector2(3.0, -9.0)
	elif backdrop_index == 5:
		mote_color = Color(0.85, 0.59, 0.27, 0.27)
		drift = Vector2(14.0, 2.0)
	elif backdrop_index == 6:
		mote_color = Color(0.9, 0.86, 0.52, 0.25)
		drift = Vector2(4.0, -4.0)
	for index: int in range(18):
		var x: float = 170.0 + fposmod(float(index * 191) + time * (8.0 + float(index % 4) * 3.0), 1570.0)
		var y: float = 205.0 + float((index * 137) % 660) + sin(time * 0.9 + index) * 15.0
		draw_line(Vector2(x, y), Vector2(x, y) + drift, mote_color, 2.0)
