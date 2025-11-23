extends Node2D

@onready var map: TileMapLayer = $BaseMap
@onready var floor: TileMapLayer = $BaseMap/floor
@onready var collisions: TileMapLayer = $BaseMap/collisions
@onready var player: CharacterBody2D = $BaseMap/player

@onready var pause: Button = $UI/HBoxContainer/Pause
@onready var retry: Button = $UI/HBoxContainer/Retry
@onready var fullscreen: Button = $UI/HBoxContainer/Fullscreen
@onready var windowed: Button = $UI/HBoxContainer/Windowed
@onready var volume: Button = $UI/HBoxContainer/Volume
@onready var exit: Button = $UI/HBoxContainer/Exit

var turret

func _ready() -> void:
	pause.button_up.connect(_on_pause_button_up)
	retry.button_up.connect(_on_retry_button_up)
	fullscreen.button_up.connect(_on_fullscreen_button_up)
	windowed.button_up.connect(_on_windowed_button_up)
	volume.button_up.connect(_on_volume_button_up)
	exit.button_up.connect(_on_exit_button_up)

func _on_retry_button_up() -> void:
	get_tree().reload_current_scene()
	
func _on_pause_button_up() -> void:
	get_tree().paused = !get_tree().paused

func _on_fullscreen_button_up() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
func _on_windowed_button_up() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_button_up() -> void:
	var bus := AudioServer.get_bus_index("Master")
	var muted := AudioServer.is_bus_mute(bus)
	AudioServer.set_bus_mute(bus, !muted)

func _on_exit_button_up() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
