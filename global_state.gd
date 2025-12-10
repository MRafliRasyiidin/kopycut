extends Node

@export var level: int = 0
@export var pickable_tile = {}

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	level = 1
