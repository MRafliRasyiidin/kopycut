extends CanvasLayer

@onready var levelNum: Label = $LevelNum

func _ready() -> void:
	levelNum.text = str(GlobalState.level)

func _on_pause_button_up() -> void:
	if get_tree().paused:
		AudioController.play_menu_click()
		AudioController.play_pause()
	else:
		AudioController.play_menu_click()
		AudioController.play_resume()
	get_tree().paused = !get_tree().paused

func _on_fullscreen_button_up() -> void:
	AudioController.play_menu_click()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
func _on_windowed_button_up() -> void:
	AudioController.play_menu_click()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_button_up() -> void:
	AudioController.play_menu_click()
	var bus := AudioServer.get_bus_index("Master")
	var muted := AudioServer.is_bus_mute(bus)
	AudioServer.set_bus_mute(bus, !muted)

func _on_exit_button_up() -> void:
	AudioController.play_menu_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
