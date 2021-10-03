extends Node2D

var instability = 0.0
var last_y_platform = 0.0
var instability_level = 1
var max_instability_level = 10
var high_score = 0
var high_time = 0


func _ready():
	load_score()


func save_score(score, time):
	if score < high_score:
		return
	var saved_score = File.new()
	saved_score.open("user://savegame.save", File.WRITE)
	saved_score.store_line(
		to_json(
			{
				"highscore": score,
				"hightime": time,
			}
		)
	)
	saved_score.close()
	high_score = score
	high_time = time


func load_score():
	var saved_score = File.new()
	if not saved_score.file_exists("user://savegame.save"):
		return
	saved_score.open("user://savegame.save", File.READ)
	var data = parse_json(saved_score.get_line())
	high_score = data["highscore"]
	high_time = data["hightime"]
