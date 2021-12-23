extends Node

const ACHIEVEMENT_JSON_USER_PATH = "user://achievements.json"
const ACHIEVEMENT_JSON_REFERENCE_PATH = "res://gd-achievements/achievements.json"

var achievements = {}
var achievementCount = 0

signal achievement_unlocked(achievement)


func _ready():
	achievements = build_from_reference_file()
	synchronize_reference_with_user_data()


func build_from_reference_file():
	var file = File.new()
	file.open(ACHIEVEMENT_JSON_REFERENCE_PATH, File.READ)
	var data = parse_json(file.get_as_text())
	for key in data.keys():
		data[key]["key"] = key
		data[key]["achieved"] = false
		if "goal" in data[key]:
			data[key]["current_progress"] = 0
	file.close()

	return data


func update_user_data_file():
	var file = File.new()
	file.open(ACHIEVEMENT_JSON_USER_PATH, File.WRITE)
	var data = {}
	for key in achievements.keys():
		data[key] = {"achieved": achievements[key]["achieved"]}
		if "current_progress" in achievements[key]:
			data[key]["current_progress"] = achievements[key]["current_progress"]

	file.store_string(to_json(achievements))
	file.close()


func update_achievements_from_user_data(user_achievements):
	for key in user_achievements.keys():
		if key in achievements and key in user_achievements:
			if "current_progress" in user_achievements[key]:
				achievements[key]["current_progress"] = user_achievements[key]["current_progress"]
			achievements[key]["achieved"] = user_achievements[key]["achieved"]


func synchronize_reference_with_user_data():
	var json_user_file = File.new()
	if not json_user_file.file_exists(ACHIEVEMENT_JSON_USER_PATH):
		update_user_data_file()
	else:
		json_user_file.open(ACHIEVEMENT_JSON_USER_PATH, File.READ)
		var user_achievements = parse_json(json_user_file.get_as_text())
		if not user_achievements:
			user_achievements = {}
		json_user_file.close()
		update_achievements_from_user_data(user_achievements)
		# In case the user file differs from the reference file (i.e. if new achievements were added), update the user file
		update_user_data_file()


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		update_user_data_file()


func progress_achievement(key, progress):
	achievements[key]["current_progress"] = min(
		progress + achievements[key]["current_progress"], achievements[key]["goal"]
	)
	if achievements[key]["current_progress"] >= achievements[key]["goal"]:
		activate_achievement(key)


func unlock_achievement(key):
	activate_achievement(key)


func get_achievement(key):
	return achievements[key]


func get_all_achievements():
	return achievements


func activate_achievement(key):
	if not achievements.has(key):
		print(
			(
				"AchievementSystem Error: Attempt to get an achievement on "
				+ key
				+ ", key doesn't exist."
			)
		)
		return

	var currentAchievement = achievements[key]

	if currentAchievement["achieved"] == false:
		achievements[key]["achieved"] = true
		update_user_data_file()

		emit_signal("achievement_unlocked", currentAchievement)


func reset_achievements():
	for key in achievements:
		achievements[key]["achieved"] = false
	update_user_data_file()
	print("AchievementSystem: reset_achievements()")
