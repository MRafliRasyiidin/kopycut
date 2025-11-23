extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var jitter: AnimatedSprite2D = $Jitter



func _ready() -> void:
	if jitter:
		jitter.play("paste")
	anim.play("hover")
