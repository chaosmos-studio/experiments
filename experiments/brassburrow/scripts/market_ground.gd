extends Node2D

const SIZE := Vector2(2380, 1500)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("c7b38a"))
	for lane in 4:
		var y := 235.0 + lane * 360.0
		draw_rect(Rect2(0, y, SIZE.x, 140), Color("d9c9aa"))
		for x in range(24, 2380, 92):
			draw_line(Vector2(x, y + 67), Vector2(x + 47, y + 67), Color("eadcc1", 0.62), 3)
	for x in range(0, 2380, 88):
		for y in range(0, 1500, 74):
			var seed := int(x * 31 + y * 79)
			var center := Vector2(x + 44 + sin(seed * 0.41) * 17, y + 36 + cos(seed * 0.22) * 11)
			draw_circle(center, 2.2, Color("aa916f", 0.19))
			if seed % 9 == 0:
				draw_circle(center + Vector2(11, -8), 2.0, Color("f8e6b8", 0.5))
	for stand in 15:
		var x := 175.0 + stand * 149.0
		var y := 140.0 + (stand % 4) * 330.0
		var fabric: Color = [Color("719786"), Color("c97966"), Color("94a7b7")][stand % 3]
		draw_rect(Rect2(x - 49, y - 23, 99, 57), Color("705344", 0.20))
		draw_rect(Rect2(x - 48, y - 35, 96, 58), fabric)
		draw_line(Vector2(x - 39, y - 23), Vector2(x + 39, y - 23), Color("f6e6c8"), 3)
		for seam in 4:
			draw_circle(Vector2(x - 35 + seam * 23, y + 9), 4, Color("f4e1af", 0.83))
