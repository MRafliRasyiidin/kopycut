extends Control

@onready var main: VBoxContainer = $Main
@onready var settings: VBoxContainer = $Settings


func _ready() -> void:
	main.visible = false
	settings.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			settings.visible = false
			get_tree().paused = !get_tree().paused
			if get_tree().paused:
				main.visible = true
			else: main.visible = false
			print("PAUSE")
			

func _on_resume_button_up() -> void:
	get_tree().paused = false
	main.visible = false
	settings.visible = false
	print("RESUME")


func _on_settings_button_up() -> void:
	main.visible = false
	settings.visible = true


func _on_exit_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	print("EXIT GAME")
	

func _on_back_button_up() -> void:
	settings.visible = false
	main.visible = true
	pass # Replace with function body.
