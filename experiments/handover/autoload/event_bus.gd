extends Node

# Typed signals only: no state, no methods, and no class_name, since the autoload name is the access path.

signal game_started
signal game_over(score: int)
signal paused_changed(paused: bool)
