extends Node2D

@onready var map: TileMapLayer = $BaseMap
@onready var floor: TileMapLayer = $BaseMap/floor
@onready var collisions: TileMapLayer = $BaseMap/collisions
@onready var player: CharacterBody2D = $BaseMap/player


@onready var retry: Button = $UI/HBoxContainer/Retry

var turret

func _ready() -> void:
	retry.button_up.connect(_on_retry_button_up)

func _on_retry_button_up() -> void:
	get_tree().reload_current_scene()
