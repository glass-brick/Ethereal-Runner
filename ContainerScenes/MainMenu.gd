extends Control

export (PackedScene) var cursor_scene = null
export (int) var max_volume = 20
export (int) var min_volume = -60
var path = []

var leaderboard_entry = load("res://Utilities/LeaderboardEntry.tscn")
onready var cursor = cursor_scene.instance()
onready var main_menu = $MarginContainer/MarginContainer/MainMenu
onready var settings_menu = $MarginContainer/MarginContainer/SettingsMenu
onready var controls_menu = $MarginContainer/MarginContainer/ControlsMenu
onready var scores_menu = $MarginContainer/MarginContainer/ScoresMenu
onready var menus = [main_menu, settings_menu, controls_menu, scores_menu]
onready var sfx_volume = $MarginContainer/MarginContainer/SettingsMenu/SFXVolume/SFXVolume
onready var bgm_volume = $MarginContainer/MarginContainer/SettingsMenu/BGMVolume/BGMVolume


# Called when the node enters the scene tree for the first time.
func _ready():
	sfx_volume.set_value(SoundManager.get_se_volume_db() + 80)
	bgm_volume.set_value(SoundManager.get_bgm_volume_db() + 80)
	open_menu(main_menu)
	add_child(cursor)
	$HTTPRequest.request(
		"{path}/leaderboard".format({"path": Globals.leaderboards_server}),
		["User-Agent: EtherealRunner/1.0"]
	)
	var seconds = int(Globals.high_time) % 60
	var minutes = int((Globals.high_time - seconds) / 60)
	scores_menu.get_node('HighScore').text = (
		"Your high score: %d in %02d:%02d"
		% [Globals.high_score, minutes, seconds]
	)
	# if Globals.player_name:
	# 	$Name/NameInput.text = Globals.player_name
	# else:
	# 	randomize()
	# 	var r = randi()
	# 	var rand_number = r % len(starter_names)
	# 	$Name/NameInput.text = starter_names[rand_number]


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

func get_volume_from_slider(value: float) -> float:
	# this assumes that value goes between 0 and 100
	return min_volume + value * (max_volume - min_volume) / 100.0

func _on_SFXVolume_value_changed(value: float):
	var vol = get_volume_from_slider(value)
	Globals.se_volume = vol
	SoundManager.set_se_volume_db(vol)

func _on_BGMVolume_value_changed(value: float):
	var vol = get_volume_from_slider(value)
	Globals.bgm_volume = vol
	SoundManager.set_bgm_volume_db(vol)


func _on_OpenControlRemapping_pressed():
	open_menu(controls_menu)


func _on_OpenLeaderboard_pressed():
	open_menu(scores_menu)


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
				var score_path = "LeaderboardList/Container/Pos{}".format([i], "{}")
				print(score_path)
				scores_menu.get_node(score_path).set_entry(int(i) + 1, points, name)

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
