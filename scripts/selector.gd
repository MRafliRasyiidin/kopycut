extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	anim.play("hover")
