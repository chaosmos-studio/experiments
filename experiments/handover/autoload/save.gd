extends Node

# ConfigFile rather than a Resource, because the file stays readable and a corrupt or older file degrades
# to defaults instead of failing to load. Rename PATH per game so two games never share a save.

const PATH: String = "user://save.cfg"
const SECTION: String = "player"

var best_score: int = 0
var music_on: bool = true
var sfx_on: bool = true

func _ready() -> void:
	restore()

func restore() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(PATH) != OK:
		return
	best_score = int(file.get_value(SECTION, "best_score", 0))
	music_on = bool(file.get_value(SECTION, "music_on", true))
	sfx_on = bool(file.get_value(SECTION, "sfx_on", true))

func store() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION, "best_score", best_score)
	file.set_value(SECTION, "music_on", music_on)
	file.set_value(SECTION, "sfx_on", sfx_on)
	file.save(PATH)
