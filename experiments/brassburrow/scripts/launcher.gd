extends Node2D

const SCENES := {
	"brassburrow": "res://scenes/main.tscn",
	"veilmarket": "res://scenes/veilmarket.tscn",
	"threadrail": "res://scenes/threadrail.tscn",
}


func _ready() -> void:
	var mode := "brassburrow"
	if OS.has_feature("web"):
		mode = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('game') || 'brassburrow'"))
	else:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("game="):
				mode = argument.trim_prefix("game=")
	if not SCENES.has(mode):
		mode = "brassburrow"
	add_child(load(SCENES[mode]).instantiate())
