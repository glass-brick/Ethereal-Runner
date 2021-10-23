extends CanvasLayer


func _on_CursorMenu_selected_option(option, menu):
	match option.name:
		"StartGame":
			start_game()
		"Tutorial":
			start_tutorial()
		"Settings":
			menu.open_menu('SettingsMenu')


func _on_CursorMenu_option_changed(option, _menu):
	match option.name:
		"BGMVolume":
			SoundManager.set_bgm_volume_db(option.value if option.value > option.min_value else -81)
		"SFXVolume":
			SoundManager.set_se_volume_db(option.value if option.value > option.min_value else -81)


func start_tutorial():
	$CursorMenu.cursor.run_animation()
	yield(get_tree().create_timer(1.0), "timeout")
	SceneManager.change_scene('res://ContainerScenes/TutorialLevel.tscn')


func start_game():
	$CursorMenu.cursor.run_animation()
	yield(get_tree().create_timer(1.0), "timeout")
	SceneManager.change_scene('res://ContainerScenes/BaseLevel.tscn')
