extends Node2D

export (int) var starting_music_volume = 0
export (float) var timer_expiration_non_taken_path = 1
export (float) var change_music_prob = 0.2

var Platform = preload('res://FloorSegment.tscn')
var PlatformSmall = preload('res://FloorSegmentSmall.tscn')
var PlatformMedium = preload('res://FloorSegmentMedium.tscn')
var PlatformXL = preload('res://FloorSegmentXL.tscn')
var PlatformIndestructible = preload('res://FloorSegmentIndestructible.tscn')
var TwitchBone = preload('res://Enemy_TwitchBone.tscn')
var FleshStump = preload('res://Enemy_FleshStump.tscn')
var TreapanoGargoyle = preload('res://Enemy_TreapanoGargoyle.tscn')
var Lightning = preload('res://Lightning.tscn')
var render_limit = [Vector2(-2000, -2000), Vector2(5000, 5000)]
var render_paths = [{"position": Vector2(0, 200), "biome": "normal", "id": randi(), "branch_on": 0}]
var time_passed = 0
var hue_value = 0
var new_path_frequency = 10
var new_path_height_diff = 400
var songs = ['Vals', 'Inferno', 'NuevoMundo']

var current_instability_level = 0

var instability_levels = [
	{
		"high_treshold": 1,
		"distance_modifier": 1,
		"monster_chance": 10,
		"max_monsters_per_platform": 1,
	},
	{
		"low_treshold": 2,
		"high_treshold": 2,
		"distance_modifier": 1.2,
		"monster_chance": 30,
		"lightning_chance": 10,
		"lightning_frequency": 300,
		"max_monsters_per_platform": 2,
	},
	{
		"low_treshold": 3,
		"high_treshold": 3,
		"distance_modifier": 1.4,
		"monster_chance": 50,
		"lightning_chance": 20,
		"lightning_frequency": 200,
		"max_monsters_per_platform": 3,
	},
	{
		"low_treshold": 4,
		"distance_modifier": 1.6,
		"monster_chance": 60,
		"lightning_chance": 20,
		"lightning_frequency": 100,
		"max_monsters_per_platform": 4,
	}
]


# Called when the node enters the scene tree for the first time.
func _ready():
	reset_music_volume()
	randomize()
	change_music("Vals")
	yield(SceneManager, 'scene_loaded')
	SceneManager.get_entity('Player').global_position = Globals.player_respawn_position


var current_dialog
var current_timeline
var last_dialogue_position


func _on_player_died():
	Globals.player_respawn_position = last_dialogue_position
	SceneManager.reload_scene()


func start_dialogue(timeline_name):
	current_timeline = timeline_name
	last_dialogue_position = SceneManager.get_entity("Player").global_position
	get_tree().paused = true
	current_dialog = Dialogic.start(timeline_name)
	current_dialog.connect('timeline_end', self, '_on_dialogue_end')
	add_child(current_dialog)


func _on_dialogue_end(_timeline_file_name):
	remove_child(current_dialog)
	current_dialog = null
	get_tree().paused = false
	if current_timeline == "Instability Spawn Rate":
		Globals.tutorial_finished = true
		Globals.save_game()
		SceneManager.change_scene('res://MainMenu.tscn')
	current_timeline = null


func _process(delta):
	change_instability_if_necessary()
	process_instability_effects()
	change_background_colors(delta)
	process_music(delta)


func change_background_colors(delta):
	hue_value += delta / 10
	time_passed += delta / 2
	var sat = abs(cos(time_passed) / 2)
	var parallaxLayers = get_node('ParallaxBackground')
	var parallaxLayer1 = parallaxLayers.get_node('ParallaxLayer')
	var parallaxLayer2 = parallaxLayers.get_node('ParallaxLayer2')
	parallaxLayer1.modulate.h = hue_value
	parallaxLayer1.modulate.s = sat
	parallaxLayer2.modulate.h = hue_value
	parallaxLayer2.modulate.s = sat


func change_instability_if_necessary():
	var instability_props = instability_levels[current_instability_level]
	if (
		instability_props.has("high_treshold")
		and instability_props["high_treshold"] < Globals.instability_level
	):
		current_instability_level += 1
	elif (
		instability_props.has("low_treshold")
		and instability_props["low_treshold"] > Globals.instability_level
	):
		current_instability_level -= 1


var lightning_timer = 0
var lightning_accuracy = 50


func process_instability_effects():
	var instability_props = instability_levels[current_instability_level]
	# TODO ESTO ESTA COMENTADO CON EL AND FALSE
	# FIXME IF YOU WANT RASHITOS
	if instability_props.has("lightning_chance") and false:
		if lightning_timer < instability_props["lightning_frequency"]:
			lightning_timer += 1
		else:
			var lightning_appears = instability_props["lightning_chance"] < rand_range(0, 100)
			if lightning_appears:
				lightning_timer = 0
				var lightning = Lightning.instance()
				var is_accurate = rand_range(0, 100) <= lightning_accuracy
				if is_accurate:
					lightning.position = SceneManager.get_entity('Player').global_position
				else:
					lightning.position = SceneManager.get_entity('Player').global_position
					lightning.position += Vector2(rand_range(-1000, 1000), rand_range(-300, -50))
				add_child(lightning)


func get_music_node(name = null):
	if not name:
		return get_node("Music")
	return get_node("Music").get_node(name)


func change_music_volume(change):
	for node in get_music_node().get_children():
		if node.has_method('stop') and node.is_playing():
			node.volume_db += change


func reset_music_volume():
	for node in get_music_node().get_children():
		if node.has_method('stop') and node.is_playing():
			node.volume_db = starting_music_volume


func start_music(name, fadein):
	stop_music(false)
	var targetNode = get_music_node(name)
	if targetNode.has_method("play"):
		if fadein:
			music_fading_in.append(targetNode)
			targetNode.volume_db = -60
		else:
			targetNode.volume_db = starting_music_volume

		targetNode.play()


func change_music(name):
	stop_music(true)
	next_music = name


var music_fading_in = []
var next_music = null
var music_fading_out = []
export (float) var fade_out_speed = 20
export (float) var change_music_level = -50
export (float) var fade_in_speed = 20


func stop_music(fadeout):
	for node in get_music_node().get_children():
		if node.has_method('stop') and node.is_playing():
			if fadeout:
				music_fading_out.append(node)
			else:
				node.stop()


func process_music(delta):
	for node in music_fading_in:
		node.volume_db += delta * fade_in_speed
		if node.volume_db > starting_music_volume:
			music_fading_in.remove(music_fading_in.bsearch(node))
	var not_change_yet = false
	for node in music_fading_out:
		node.volume_db -= delta * fade_out_speed
		if node.volume_db < -80:
			music_fading_out.remove(music_fading_out.bsearch(node))
			node.stop()
		if node.volume_db > change_music_level:
			not_change_yet = true
	if next_music and not not_change_yet:
		start_music(next_music, true)
		next_music = null
