extends Node2D

const SIZE := Vector2(2600, 1500)
const ISLANDS := [
	Vector2(155, 745), Vector2(545, 475), Vector2(970, 880),
	Vector2(1390, 500), Vector2(1820, 895), Vector2(2260, 690)
]


func _ready() -> void:
	queue_redraw()


func is_safe(point: Vector2) -> bool:
	for island in ISLANDS:
		if point.distance_to(island) < 215:
			return true
	return false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("427f91"))
	for x in range(0, 2600, 75):
		for y in range(0, 1500, 64):
			var seed := x * 41 + y * 37
			var wave := Vector2(x + sin(seed * 0.005) * 18, y + cos(seed * 0.008) * 19)
			draw_arc(wave, 16 + seed % 8, 0.2, 2.3, 11, Color("bbe8d4", 0.15), 2)
	for index in ISLANDS.size() - 1:
		var a: Vector2 = ISLANDS[index]
		var b: Vector2 = ISLANDS[index + 1]
		draw_line(a, b, Color("d8d5a4", 0.23), 25)
		draw_line(a, b, Color("e8d7a6", 0.39), 4)
	for index in ISLANDS.size():
		var center: Vector2 = ISLANDS[index]
		draw_circle(center + Vector2(8, 12), 241, Color("204b55", 0.28))
		draw_circle(center, 235, Color("d8bc80"))
		draw_circle(center, 219, Color("85a275") if index % 2 == 0 else Color("9dad79"))
		draw_arc(center, 208, 0, TAU, 80, Color("e4d5a0", 0.39), 5)
		for mark in 35:
			var angle := float(mark * 61 + index * 53) * 0.37
			var radius := 35 + (mark * 31) % 168
			var spot := center + Vector2(cos(angle), sin(angle)) * radius
			draw_line(spot, spot + Vector2(2, -7), Color("c0cc92", 0.65), 2)
			if mark % 5 == 0:
				draw_circle(spot + Vector2(2, -8), 3, Color("f4dfac"))
