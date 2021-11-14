extends Control

export (PackedScene) var cursor_scene = null
export (int) var max_volume = 0
export (int) var min_volume = -20
var path = []

var leaderboard_entry = load("res://Utilities/LeaderboardEntry.tscn")
var achievement_entry = load("res://Utilities/SingleAchievementPanel.tscn")
onready var cursor = cursor_scene.instance()
onready var main_menu = $MarginContainer/MainMenu
onready var main_menu_options = $MarginContainer/MainMenu/Options
onready var scores_menu = $MarginContainer/MainMenu/Scores
onready var settings_menu = $MarginContainer/SettingsMenu
onready var controls_menu = $MarginContainer/ControlsMenu
onready var achievements_menu = $MarginContainer/AchievementsMenu
onready var achievements_menu_options = $MarginContainer/AchievementsMenu/GridContainer
onready var achievements_next_button = $MarginContainer/AchievementsMenu/VBoxContainer/HBoxContainer/NextPage
onready var achievements_prev_button = $MarginContainer/AchievementsMenu/VBoxContainer/HBoxContainer/PrevPage
onready var menus = [main_menu, settings_menu, controls_menu, achievements_menu]
onready var cursor_align_menus = [main_menu_options, achievements_menu_options]
onready var sfx_volume = $MarginContainer/SettingsMenu/SFXVolume/SFXVolume
onready var bgm_volume = $MarginContainer/SettingsMenu/BGMVolume/BGMVolume

onready var achievements = AchievementManager.get_all_achievements().values()
var current_achievement_page = 0

var time_between_scroll = 10
var scroll_timer = time_between_scroll
var scroll_direction = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	$MainMenuMusic.play()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('SoundEffects'), Globals.se_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), Globals.bgm_volume)
	sfx_volume.set_value(Globals.se_volume + 80)
	bgm_volume.set_value(Globals.bgm_volume + 80)
	open_menu(main_menu)
	add_child(cursor)
	$HTTPRequest.request(
		"{path}/leaderboard".format({"path": Globals.leaderboards_server}),
		["User-Agent: EtherealRunner/1.0"]
	)
	var seconds = int(Globals.high_time) % 60
	var minutes = int((Globals.high_time - seconds) / 60)
	scores_menu.get_node('HighScore').text = (
		"Your high score:\n%d in %02d:%02d"
		% [Globals.high_score, minutes, seconds]
	)
	update_achievements_page()


var focused_element = null


func update_achievements_page():
	var options_per_page = achievements_menu_options.get_child_count()

	for i in range(0, options_per_page):
		var array_idx = current_achievement_page * options_per_page + i
		if achievements.size() > array_idx:
			achievements_menu_options.get_child(i).set_achievement(
				achievements[array_idx]
			)
			achievements_menu_options.get_child(i).visible = true
		else:
			achievements_menu_options.get_child(i).visible = false

	var prev_disabled = current_achievement_page == 0
	var next_disabled = current_achievement_page == ceil(float(achievements.size()) / options_per_page) - 1
	achievements_prev_button.disabled = prev_disabled
	achievements_prev_button.focus_mode = FOCUS_NONE if prev_disabled else FOCUS_ALL
	achievements_next_button.disabled = next_disabled
	achievements_next_button.focus_mode = FOCUS_NONE if next_disabled else FOCUS_ALL


func _process(delta):
	if scores_menu.visible and scroll_timer == 0:
		var prev_scroll_vertical = scores_menu.get_node('LeaderboardList').scroll_vertical
		scores_menu.get_node('LeaderboardList').scroll_vertical += 1 * scroll_direction
		var new_scroll_vertical = scores_menu.get_node('LeaderboardList').scroll_vertical
		if prev_scroll_vertical == new_scroll_vertical:
			scroll_direction *= -1
		scroll_timer = time_between_scroll
	else:
		scroll_timer -= 1

	if focused_element == get_focus_owner():
		return
	focused_element = get_focus_owner()
	if focused_element:
		var cursor_node = focused_element
		while (
			menus.find(cursor_node.get_parent()) == -1
			and cursor_align_menus.find(cursor_node.get_parent()) == -1
		):
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
	yield(get_tree().create_timer(0.5), "timeout")
	SceneManager.change_scene('res://ContainerScenes/BaseLevel.tscn', { "pattern": "horizontal" })


func _on_StartTutorial_pressed():
	cursor.run_animation()
	yield(get_tree().create_timer(0.5), "timeout")
	SceneManager.change_scene('res://ContainerScenes/TutorialLevel.tscn', { "pattern": "horizontal" })


func _on_OpenSettings_pressed():
	open_menu(settings_menu)


func _on_Achievements_pressed():
	open_menu(achievements_menu)


func get_volume_from_slider(value: float) -> float:
	# this assumes that value goes between 0 and 100
	return min_volume + value * (max_volume - min_volume) / 100.0


func _on_SFXVolume_value_changed(value: float):
	var vol = get_volume_from_slider(value)
	Globals.se_volume = vol
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('SoundEffects'), vol)
	Globals.save_game()


func _on_BGMVolume_value_changed(value: float):
	var vol = get_volume_from_slider(value)
	Globals.bgm_volume = vol
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), vol)
	Globals.save_game()


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


func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = parse_json(body.get_string_from_utf8())
		if json:
			for i in json.keys():
				if not json[i]:
					continue
				var name = json[i].get('name', '')
				var points = json[i].get('points', '')
				var time = json[i].get('time', '')
				var score_path = "LeaderboardList/Container/Pos{}".format([i], "{}")
				scores_menu.get_node(score_path).set_entry(int(i) + 1, points, name, time)

	else:
		scores_menu.get_node('ErrorMsg').visible = true


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


func _exit_tree():
	$MainMenuMusic.stop()


func _on_NextPage_pressed():
	current_achievement_page += 1
	update_achievements_page()
	# if no focus, it means the pressed button is disabled now, focus the opposite button
	if not is_instance_valid(get_focus_owner()):
		achievements_prev_button.grab_focus()


func _on_PrevPage_pressed():
	current_achievement_page -= 1
	update_achievements_page()
	# if no focus, it means the pressed button is disabled now, focus the opposite button
	if not is_instance_valid(get_focus_owner()):
		achievements_next_button.grab_focus()

