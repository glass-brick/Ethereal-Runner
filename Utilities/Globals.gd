extends Node2D

var instability = 0.0
var last_y_platform = 0.0
var instability_level = 1
var max_instability_level = 10
var high_score = 0
var high_time = 0
var player_respawn_position = Vector2(0, 0)
var tutorial_finished = false
var player_name = ""
var leaderboards_server = "https://ethereal-runner-server.gggelo.repl.co"


func _ready():
	load_game()


func save_score(score, time):
	if score < high_score:
		return
	var saved_score = File.new()
	saved_score.open("user://savegame.save", File.WRITE)
	saved_score.store_line(
		to_json({"highscore": score, "hightime": time, "tutorial_finished": tutorial_finished})
	)
	saved_score.close()
	high_score = score
	high_time = time


func save_game():
	var saved_score = File.new()
	saved_score.open("user://savegame.save", File.WRITE)
	saved_score.store_line(
		to_json(
			{"highscore": high_score, "hightime": high_time, "tutorial_finished": tutorial_finished}
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
	if data.has("tutorial_finished"):
		tutorial_finished = data["tutorial_finished"]
