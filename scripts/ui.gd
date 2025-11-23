extends CanvasLayer

@onready var volume_slider: Control = $VolumeSlider
@onready var music_slider: HSlider = $VolumeSlider/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $VolumeSlider/VBoxContainer/SFXSlider
@onready var levelNum: Label = $LevelNum

func _ready() -> void:
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
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
	volume_slider.visible = !volume_slider.visible

func _on_exit_button_up() -> void:
	AudioController.play_menu_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))
