class_name CompassWorldView
extends Node2D

var level: Dictionary = {}
var phase: int = 0
var collected: Array[bool] = []
var pad_armed: bool = false
var door_open: bool = false
var time: float = 0.0
var gravity_direction: Vector2 = Vector2.DOWN
var shift_origin: Vector2 = Vector2.ZERO
var shift_age: float = 1.0


func _process(delta: float) -> void:
	time += delta
	shift_age += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-200, -100, 2320, 1280), Color("f8f4e9"))
	_draw_sky()
	_draw_room()
	if level.is_empty():
		return
	_draw_gear(Vector2(960, 538), 176, time * 0.18, Color("d6e4d8"))
	_draw_gear(Vector2(1655, 332), 62, -time * 0.48, Color("e0dfcf"))
	for wall: Rect2 in level["walls"]:
		_draw_wall(wall)
	for bridge: Rect2 in level["phase_walls"]:
		_draw_bridge(bridge)
	for hazard: Rect2 in level["hazards"]:
		_draw_hazard(hazard)
	for index: int in range(collected.size()):
		if not collected[index]:
			_draw_shard(level["shards"][index], index)
	if level["pad"] != Vector2.ZERO:
		_draw_pad(level["pad"])
	_draw_door(level["exit"])
	_draw_motes()
	if shift_age < 0.55:
		var radius: float = 50.0 + shift_age * 340.0
		draw_arc(shift_origin, radius, 0.0, TAU, 64, Color(0.24, 0.8, 0.75, (0.55 - shift_age) * 0.7), 8.0, true)


func _draw_sky() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("f5efe1"))
	for index: int in range(12):
		var x: float = 80.0 + float(index * 177) + 14.0 * sin(time * 0.3 + index)
		var y: float = 85.0 + float((index * 89) % 700)
		draw_circle(Vector2(x, y), 2.0 + float(index % 3), Color("e3c582"))
	draw_arc(Vector2(1550, 255), 250, -PI * 0.15, PI * 1.55, 48, Color("e4d3a4"), 14.0, true)
	draw_arc(Vector2(1550, 255), 282, PI * 0.2, PI * 1.77, 48, Color("ebdfbf"), 5.0, true)
	draw_circle(Vector2(1550, 255), 147, Color("e2e7d9"))
	draw_circle(Vector2(1520, 225), 86, Color("ecf3e8"))


func _draw_room() -> void:
	draw_rect(Rect2(85, 145, 1750, 800), Color("d2dbcd"), true)
	draw_rect(Rect2(105, 165, 1710, 760), Color("fcfbf4"), true)
	for x: int in range(230, 1790, 230):
		draw_line(Vector2(x, 199), Vector2(x, 898), Color("ebeee4"), 3.0)
	for y: int in range(293, 900, 125):
		draw_line(Vector2(140, y), Vector2(1780, y), Color("eef0e7"), 3.0)
	for index: int in range(6):
		var cx: float = 250.0 + index * 280.0
		draw_circle(Vector2(cx, 540), 98, Color("e3eee9"))
		draw_circle(Vector2(cx, 540), 80, Color("e7f5f1"))
		draw_circle(Vector2(cx + 24, 528), 35, Color("f6f8ed"))
	draw_rect(Rect2(110, 168, 1700, 760), Color("b9c9bd"), false, 7.0)


func _draw_wall(wall: Rect2) -> void:
	draw_rect(wall.grow(5), Color("294a52"), true)
	draw_rect(wall, Color("668487"), true)
	var inner: Rect2 = wall.grow(-7)
	if inner.size.x > 0.0 and inner.size.y > 0.0:
		draw_rect(inner, Color("d2e1d8"), true)
	if wall.size.x > wall.size.y:
		for x: float in range(int(wall.position.x + 26), int(wall.end.x - 8), 56):
			draw_circle(Vector2(x, wall.position.y + wall.size.y * 0.5), 3.0, Color("46737a"))
	else:
		for y: float in range(int(wall.position.y + 24), int(wall.end.y - 8), 52):
			draw_circle(Vector2(wall.position.x + wall.size.x * 0.5, y), 3.0, Color("46737a"))


func _draw_bridge(bridge: Rect2) -> void:
	var on: bool = phase == 1
	var color: Color = Color("4ccac0") if on else Color("88b4b4")
	color.a = 0.9 if on else 0.27
	draw_rect(bridge.grow(10), Color(0.3, 0.8, 0.75, 0.12 if on else 0.04), true)
	draw_rect(bridge, color, true)
	for x: float in range(int(bridge.position.x + 18), int(bridge.end.x), 34):
		draw_line(Vector2(x, bridge.position.y + 5), Vector2(x - 9, bridge.end.y - 5), Color("f5fff1", 0.8 if on else 0.2), 3.0)


func _draw_hazard(area: Rect2) -> void:
	draw_rect(area.grow(8), Color(0.98, 0.33, 0.31, 0.13 + 0.08 * sin(time * 7.0)), true)
	draw_rect(area, Color("8a313f"), true)
	for x: float in range(int(area.position.x + 14), int(area.end.x), 27):
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(x - 11, area.position.y),
			Vector2(x, area.position.y - 21),
			Vector2(x + 11, area.position.y),
		])
		draw_colored_polygon(points, Color("f16a54"))


func _draw_shard(point: Vector2, index: int) -> void:
	var bob: float = sin(time * 3.0 + index * 2.0) * 9.0
	var pos: Vector2 = point + Vector2(0, bob)
	draw_circle(pos, 43, Color(1.0, 0.79, 0.35, 0.12))
	draw_circle(pos, 30, Color(1.0, 0.79, 0.35, 0.2))
	var diamond: PackedVector2Array = PackedVector2Array([pos + Vector2(0, -26), pos + Vector2(19, 0), pos + Vector2(0, 26), pos + Vector2(-19, 0)])
	draw_colored_polygon(diamond, Color("f5bd61"))
	draw_line(pos + Vector2(0, -20), pos + Vector2(0, 18), Color("fff7cd"), 5.0)
	draw_line(pos + Vector2(-11, 0), pos + Vector2(11, 0), Color("fff7cd"), 4.0)


func _draw_pad(pos: Vector2) -> void:
	var color: Color = Color("23b9b0") if pad_armed else Color("698489")
	draw_rect(Rect2(pos.x - 58, pos.y - 9, 116, 24), Color("274f5a"), true)
	draw_rect(Rect2(pos.x - 48, pos.y - 17, 96, 19), color, true)
	draw_circle(pos + Vector2(0, -8), 7.0 + 2.0 * sin(time * 5.0), Color("e3fff2") if pad_armed else Color("b3c7c7"))


func _draw_door(pos: Vector2) -> void:
	var color: Color = Color("eeb964") if door_open else Color("8aa4a5")
	draw_circle(pos, 73, Color(color, 0.18))
	draw_arc(pos, 58, 0, TAU, 52, Color("2c6268"), 14.0, true)
	draw_arc(pos, 44, 0, TAU, 52, color, 9.0, true)
	draw_circle(pos, 30, Color("fff9e2") if door_open else Color("dce6df"))
	if door_open:
		draw_circle(pos, 18 + sin(time * 6.0) * 3.0, Color("fff1b1"))
	else:
		draw_line(pos + Vector2(-14, -13), pos + Vector2(14, 13), Color("5b777a"), 7.0)
		draw_line(pos + Vector2(14, -13), pos + Vector2(-14, 13), Color("5b777a"), 7.0)


func _draw_gear(center: Vector2, radius: float, angle: float, color: Color) -> void:
	draw_arc(center, radius, 0, TAU, 64, color, 16.0, true)
	for tooth: int in range(12):
		var a: float = angle + tooth * TAU / 12.0
		var unit: Vector2 = Vector2.RIGHT.rotated(a)
		draw_line(center + unit * (radius - 24), center + unit * (radius + 20), color, 18.0)
	draw_circle(center, radius * 0.23, color)
	draw_circle(center, radius * 0.13, Color("fcfbf4"))


func _draw_motes() -> void:
	for index: int in range(18):
		var x: float = 180.0 + fposmod(float(index * 197) + time * (9.0 + float(index % 4) * 4.0), 1540.0)
		var y: float = 215.0 + float((index * 149) % 620) + sin(time * 0.8 + index) * 13.0
		draw_circle(Vector2(x, y), 2.0 + float(index % 3), Color(0.39, 0.74, 0.65, 0.25))
