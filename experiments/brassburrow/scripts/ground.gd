extends Node2D

const WORLD := Vector2(2380, 1500)
const GRASS := [Color("7a9465"), Color("8a9b6d"), Color("6c885d"), Color("94a274")]
const DUSK := [Color("84977d"), Color("7d927e"), Color("718b78"), Color("97a489")]
const MARSH := [Color("718e8a"), Color("78938c"), Color("65847f"), Color("879e92")]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD), Color("708c60"))
	draw_rect(Rect2(810, 0, 830, 1500), Color("82947b"))
	draw_rect(Rect2(1640, 0, 740, 1500), Color("6c8983"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 47912
	for i in 260:
		var x := rng.randf_range(0, WORLD.x)
		var y := rng.randf_range(0, WORLD.y)
		var palette := GRASS if x < 810 else DUSK if x < 1640 else MARSH
		var color: Color = palette[rng.randi_range(0, 3)]
		color.a = 0.20
		draw_circle(Vector2(x, y), rng.randf_range(28, 100), color)
	for i in 1650:
		var x := rng.randf_range(0, WORLD.x)
		var y := rng.randf_range(0, WORLD.y)
		var palette := GRASS if x < 810 else DUSK if x < 1640 else MARSH
		var color: Color = palette[rng.randi_range(0, 3)]
		var blade := rng.randf_range(3, 8)
		draw_line(Vector2(x, y), Vector2(x - 3, y - blade), color.lightened(0.10), 1.3)
		draw_line(Vector2(x, y), Vector2(x + 2, y - blade * 0.8), color.darkened(0.13), 1.1)
		if rng.randf() < 0.055:
			draw_circle(Vector2(x + 7, y - 5), 3.4, Color("f1ddb0"))
			draw_circle(Vector2(x + 7, y - 5), 1.3, Color("a56737"))
	var road := PackedVector2Array([
		Vector2(0, 610), Vector2(370, 616), Vector2(720, 674),
		Vector2(1100, 643), Vector2(1500, 680), Vector2(1900, 661),
		Vector2(2380, 690), Vector2(2380, 900), Vector2(1900, 861),
		Vector2(1500, 876), Vector2(1100, 843), Vector2(720, 880),
		Vector2(370, 818), Vector2(0, 804)
	])
	draw_colored_polygon(road, Color("a28d63"))
	for i in range(0, 2380, 56):
		var curve := sin(float(i) * 0.009) * 19.0
		draw_circle(Vector2(i + 12, 710 + curve + rng.randf_range(-70, 70)), rng.randf_range(2, 6), Color("7f7659"))
		if i % 3 == 0:
			draw_line(Vector2(i, 732 + curve), Vector2(i + 21, 735 + curve), Color("d1b783", 0.28), 2.0)
	for i in range(65):
		var x := rng.randf_range(0, WORLD.x)
		var y := rng.randf_range(0, WORLD.y)
		if y > 560 and y < 940:
			continue
		draw_circle(Vector2(x + 3, y + 5), 8, Color(0.16, 0.19, 0.14, 0.24))
		draw_circle(Vector2(x, y), rng.randf_range(4, 9), Color("9a9c81"))
		draw_circle(Vector2(x - 2, y - 2), 2, Color("d6cf9e", 0.6))
	draw_rect(Rect2(Vector2.ZERO, Vector2(2380, 12)), Color("354936"))
	draw_rect(Rect2(0, 1488, 2380, 12), Color("354936"))
