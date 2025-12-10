extends Node2D

@onready var map: TileMapLayer = $BaseMap
@onready var floor: TileMapLayer = $BaseMap/floor
@onready var collisions: TileMapLayer = $BaseMap/collisions
@onready var player: CharacterBody2D = $BaseMap/player
@onready var pickables: TileMapLayer = $BaseMap/pickables

@onready var retry: Button = $UI/HBoxContainer/Retry

var turret

func _ready() -> void:
	GlobalState.pickable_tile = {}
	var all_pickables = pickables.get_used_cells()
	for coords in all_pickables:
		GlobalState.pickable_tile[coords] = pickables.get_preview_mode(coords)
	retry.button_up.connect(_on_retry_button_up)

func _on_retry_button_up() -> void:
	get_tree().reload_current_scene()
