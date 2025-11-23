extends Node2D

@onready var folder: AnimatedSprite2D = $Folder
@onready var portal: AnimatedSprite2D = $Portal

func _ready() -> void:
	folder.play("idle")
	
func open_portal():
	folder.play("open_folder")
	portal.show()
	portal.play("idle")
	await folder.animation_finished
	folder.play("open_idle")
	await portal.animation_finished
	portal.play("open_idle")
	
func close_portal() -> void:
	portal.play("closed")
	folder.play("close_folder")
	await folder.animation_finished
	folder.play("idle")
	portal.hide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		open_portal()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print('bunnegirl')
		await close_portal()
