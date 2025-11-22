extends Node2D

@onready var map: TileMapLayer = $BaseMap
@onready var floor: TileMapLayer = $BaseMap/floor
@onready var collisions: TileMapLayer = $BaseMap/collisions
@onready var player: CharacterBody2D = $BaseMap/player

var turret

func _ready() -> void:
	collisions.modulate = Color(0,0,0,0)

func _on_retry_button_up() -> void:
	get_tree().reload_current_scene()
	pass # Replace with function body.
