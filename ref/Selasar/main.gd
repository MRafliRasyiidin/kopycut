extends Node2D

@onready var map: TileMapLayer = $BaseMap
@onready var floor: TileMapLayer = $BaseMap/floor
@onready var collisions: TileMapLayer = $BaseMap/collisions
@onready var player: CharacterBody2D = $BaseMap/player


func _ready() -> void:
	collisions.modulate = Color(0,0,0,0)
	pass


func _on_button_button_up() -> void:
	get_tree().reload_current_scene()
	pass # Replace with function body.
