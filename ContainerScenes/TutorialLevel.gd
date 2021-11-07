extends Node2D

var time_passed = 0
var hue_value = 0
var is_tutorial = true


func _ready():
	randomize()
	SoundManager.play_bgm('Wind')
	yield(SceneManager, 'scene_loaded')
	SceneManager.get_entity('Player').global_position = Globals.player_respawn_position


var current_dialog
var current_timeline


func start_dialogue(timeline_name):
	current_timeline = timeline_name
	Globals.player_respawn_position = SceneManager.get_entity("Player").global_position
	get_tree().paused = true
	current_dialog = Dialogic.start(timeline_name)
	current_dialog.connect('timeline_end', self, '_on_dialogue_end')
	add_child(current_dialog)
	SceneManager.get_entity('HUD').hide_tutorial_message()


func show_overhead_message(text_to_show):
	SceneManager.get_entity('HUD').show_tutorial_message(text_to_show)


func _on_dialogue_end(_timeline_file_name):
	remove_child(current_dialog)
	current_dialog = null
	get_tree().paused = false
	if current_timeline == "Objective":
		Globals.tutorial_finished = true
		Globals.player_respawn_position = Vector2(0, 0)
		Globals.save_game()
		SceneManager.change_scene('res://ContainerScenes/MainMenu.tscn')
	elif current_timeline == "Magic":
		SceneManager.get_entity("Player").mana_gather_factor = 10
	elif current_timeline == "Attack":
		SceneManager.get_entity("Player").mana += 0
	current_timeline = null


func _process(delta):
	change_background_colors(delta)


func change_background_colors(delta):
	hue_value += delta / 10
	time_passed += delta / 2
	var sat = abs(cos(time_passed) / 2)
	var parallaxLayers = get_node('ParallaxBackground')
	var parallaxLayer1 = parallaxLayers.get_node('ParallaxLayer')
	parallaxLayer1.modulate.h = hue_value
	parallaxLayer1.modulate.s = sat


func _exit_tree():
	SoundManager.stop('Wind')
