extends Node2D

var instability = 0.0
var last_y_platform = 0.0
var instability_level = 1
var max_instability_level = 10
var high_score = 0
var high_time = 0
var player_respawn_position = Vector2(0, 0)
var player_respawn_gather_factor = 0
var player_name = ""
var leaderboards_server = "https://ethereal-runner-server.gggelo.repl.co"

var bgm_volume = 0 setget set_bgm_volume
var se_volume = 0 setget set_se_volume
var max_volume = 0
var min_volume = -20


func serialize_keybindings():
	var keybindings = {}
	for action_name in ['fire', 'jump', 'dash', 'shield']:
		var binding_list = []
		for key_event in InputMap.get_action_list(action_name):
			binding_list.append(key_event.scancode)
		keybindings[action_name] = binding_list
	return keybindings


func apply_serialized_keybindings(keybindings):
	for action_name in keybindings:
		var binding_list = keybindings[action_name]
		InputMap.action_erase_events(action_name)
		for scancode in binding_list:
			var key_event = InputEventKey.new()
			key_event.scancode = scancode
			InputMap.action_add_event(action_name, key_event)


func _ready():
	load_game()
	load_settings()


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_game()
		save_settings()


func save_settings():
	var file = File.new()
	file.open("user://settings.json", File.WRITE)
	file.store_line(
		to_json(
			{
				"keybindings": serialize_keybindings(),
				"bgm_volume": bgm_volume,
				"se_volume": se_volume,
				"player_name": player_name,
			}
		)
	)

func set_bgm_volume(value: float):
	bgm_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), Globals.bgm_volume)
	if value <= min_volume:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)

func set_se_volume(value: float):
	se_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('SoundEffects'), Globals.se_volume)
	if value <= min_volume:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundEffects"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundEffects"), false)


func load_settings():
	var file = File.new()
	if not file.file_exists("user://settings.json"):
		return
	file.open("user://settings.json", File.READ)
	var data = parse_json(file.get_line())
	set_bgm_volume(data["bgm_volume"] if data.has("bgm_volume") else 0)
	set_se_volume(data["se_volume"] if data.has("se_volume") else 0)
	apply_serialized_keybindings(data["keybindings"] if data.has("keybindings") else {})
	player_name = data["player_name"] if data.has("player_name") else ""


func save_score(score, time):
	if score < high_score:
		return
	save_game()
	high_score = score
	high_time = time


func save_game():
	var saved_score = File.new()
	saved_score.open("user://savegame.save", File.WRITE)
	saved_score.store_line(
		to_json(
			{
				"highscore": high_score,
				"hightime": high_time,
			}
		)
	)
	saved_score.close()


func load_game():
	var saved_score = File.new()
	if not saved_score.file_exists("user://savegame.save"):
		return
	saved_score.open("user://savegame.save", File.READ)
	var data = parse_json(saved_score.get_line())
	high_score = data["highscore"]
	high_time = data["hightime"]
