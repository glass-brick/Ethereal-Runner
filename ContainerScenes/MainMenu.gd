extends Control

export (PackedScene) var cursor_scene = null
var path = []

onready var cursor = cursor_scene.instance()
onready var main_menu = $MarginContainer/MarginContainer/MainMenu
onready var settings_menu = $MarginContainer/MarginContainer/SettingsMenu
onready var controls_menu = $MarginContainer/MarginContainer/ControlsMenu
onready var menus = [main_menu, settings_menu, controls_menu]
onready var sfx_volume = $MarginContainer/MarginContainer/SettingsMenu/SFXVolume/SFXVolume
onready var bgm_volume = $MarginContainer/MarginContainer/SettingsMenu/BGMVolume/BGMVolume


# Called when the node enters the scene tree for the first time.
func _ready():
	sfx_volume.set_value(SoundManager.get_se_volume_db() + 80)
	bgm_volume.set_value(SoundManager.get_bgm_volume_db() + 80)
	open_menu(main_menu)
	add_child(cursor)


var focused_element = null


func _process(delta):
	if focused_element == get_focus_owner():
		return
	focused_element = get_focus_owner()
	if focused_element:
		var cursor_node = focused_element
		while menus.find(cursor_node.get_parent()) == -1:
			cursor_node = cursor_node.get_parent()
		cursor.visible = true
		cursor.rect_global_position = (
			cursor_node.rect_global_position
			+ Vector2(-40, cursor_node.rect_size.y / 2)
		)
	else:
		cursor.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_StartGame_pressed():
	cursor.run_animation()
	yield(get_tree().create_timer(1.0), "timeout")
	SceneManager.change_scene('res://ContainerScenes/BaseLevel.tscn')


func _on_StartTutorial_pressed():
	cursor.run_animation()
	yield(get_tree().create_timer(1.0), "timeout")
	SceneManager.change_scene('res://ContainerScenes/TutorialLevel.tscn')


func _on_OpenSettings_pressed():
	open_menu(settings_menu)


func _on_SFXVolume_value_changed(value: float):
	SoundManager.set_se_volume_db(value - 80)


func _on_BGMVolume_value_changed(value: float):
	SoundManager.set_bgm_volume_db(value - 80)


func _on_OpenControlRemapping_pressed():
	open_menu(controls_menu)


func _on_GoBack_pressed():
	go_back()


func go_back():
	path.pop_back()
	toggle_menu(path.back())


func open_menu(menu_to_open):
	path.append(menu_to_open)
	toggle_menu(menu_to_open)


func toggle_menu(menu_to_open):
	for menu in menus:
		menu.visible = menu == menu_to_open
		if menu == menu_to_open:
			var child = find_focusable_child(menu)
			if child:
				child.grab_focus()
			else:
				push_error("No focusable child found in node " + menu.name)


func find_focusable_child(node):
	if node.focus_mode == 2:
		return node
	for child in node.get_children():
		if child.focus_mode == 2:
			return child
		else:
			var result = find_focusable_child(child)
			if result:
				return result
	return null
