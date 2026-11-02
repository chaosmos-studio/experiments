class_name CompassLevels
extends RefCounted

const FRAME: Array[Rect2] = [
	Rect2(110, 168, 1700, 30),
	Rect2(110, 898, 1700, 30),
	Rect2(110, 168, 30, 760),
	Rect2(1780, 168, 30, 760),
]


static func count() -> int:
	return 4


static func get_level(index: int) -> Dictionary:
	var base: Dictionary = {
		"start": Vector2(270, 822),
		"exit": Vector2(1705, 815),
		"walls": FRAME.duplicate(),
		"phase_walls": [],
		"hazards": [],
		"crate": Vector2.ZERO,
		"pad": Vector2.ZERO,
		"shards": [],
	}
	match index:
		0:
			base.merge({
				"name": "THE ARRIVAL",
				"hint": "Run, jump, then turn gravity to climb the lift shaft.",
				"accent": Color("25b7b3"),
				"walls": FRAME + [Rect2(810, 628, 34, 270), Rect2(1030, 478, 330, 28)],
				"shards": [Vector2(525, 760), Vector2(976, 370), Vector2(1488, 728)],
			}, true)
		1:
			base.merge({
				"name": "THE PRISM WORKS",
				"hint": "Every turn also changes which light bridges are solid.",
				"accent": Color("ed815f"),
				"walls": FRAME + [Rect2(545, 680, 28, 218), Rect2(1170, 560, 28, 338)],
				"phase_walls": [Rect2(620, 568, 310, 26), Rect2(1250, 430, 260, 26)],
				"hazards": [Rect2(884, 870, 200, 28)],
				"shards": [Vector2(425, 310), Vector2(1000, 490), Vector2(1500, 340)],
			}, true)
		2:
			base.merge({
				"name": "CARGO CLOCK",
				"hint": "Push the brass cargo onto the blue plate. It stays armed.",
				"accent": Color("dba23d"),
				"crate": Vector2(488, 835),
				"pad": Vector2(764, 876),
				"walls": FRAME + [Rect2(1070, 548, 32, 350), Rect2(1290, 455, 270, 28)],
				"hazards": [Rect2(1110, 870, 145, 28)],
				"shards": [Vector2(590, 368), Vector2(1198, 392), Vector2(1580, 725)],
			}, true)
		3:
			base.merge({
				"name": "THE DAWN ENGINE",
				"hint": "Carry the last spark through both sides of the engine.",
				"accent": Color("945dc4"),
				"walls": FRAME + [Rect2(610, 550, 32, 348), Rect2(975, 285, 32, 360), Rect2(1345, 540, 32, 358)],
				"phase_walls": [Rect2(675, 485, 260, 26), Rect2(1040, 712, 260, 26)],
				"hazards": [Rect2(745, 870, 130, 28), Rect2(1465, 870, 120, 28)],
				"shards": [Vector2(405, 313), Vector2(1060, 354), Vector2(1580, 335)],
			}, true)
	return base
