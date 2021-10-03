extends Node2D

var Platform = preload('res://FloorSegment.tscn')
var Monster = preload('res://Enemy1.tscn')
var Lightning = preload('res://Lightning.tscn')
onready var camera = $Player/Camera2D
onready var last_camera_position = camera.get_camera_screen_center().x
var render_limit = [-2000, 5000]
var render_position = Vector2(0, 200)

var current_instability_level = 0

var instability_levels = [
	{
		"high_treshold": 1,
		"min_distance": 800,
		"max_distance": 1100,
		"max_height_diff": 50,
		"min_height_diff": 150,
		"monster_chance": 0,
	},
	{
		"high_treshold": 2,
		"min_distance": 800,
		"max_distance": 1100,
		"max_height_diff": 50,
		"min_height_diff": 150,
		"monster_chance": 20,
		"lightning_chance": 10,
		"lightning_frequency": 300,
	},
	{
		"low_treshold": 3,
		"high_treshold": 4,
		"min_distance": 900,
		"max_distance": 1200,
		"max_height_diff": 100,
		"min_height_diff": 150,
		"monster_chance": 40,
		"lightning_chance": 20,
		"lightning_frequency": 200,
	},
	{
		"low_treshold": 4,
		"min_distance": 1100,
		"max_distance": 1400,
		"max_height_diff": 120,
		"min_height_diff": 200,
		"monster_chance": 60,
		"lightning_chance": 20,
		"lightning_frequency": 100,
	}
]

var platforms = []
var monsters = []


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

	while render_position.x < render_limit[1]:
		render_platform()


func render_platform():
	var instability_props = instability_levels[current_instability_level]
	var platform = Platform.instance()
	platform.position = render_position
	add_child(platform)
	platforms.push_back(platform)
	var spawn_monster = randi() % 100 <= instability_props["monster_chance"]
	if spawn_monster:
		var monster = Monster.instance()
		monster.position = render_position
		monster.position.y -= 300
		add_child(monster)
		monsters.push_back(monster)

	render_position.x += (
		instability_props["min_distance"]
		+ randi() % (instability_props["max_distance"] - instability_props["min_distance"])
	)
	render_position.y += (
		(randi() % (instability_props["max_height_diff"] + instability_props["min_height_diff"]))
		- instability_props["max_height_diff"]
	)
	Globals.last_y_platform = render_position.y


func _process(delta):
	process_platforms()
	change_instability_if_necessary()
	process_instability_effects()


func process_platforms():
	var new_camera_position = camera.get_camera_screen_center().x
	var instability_props = instability_levels[current_instability_level]
	if new_camera_position > last_camera_position:
		var diff = new_camera_position - last_camera_position
		last_camera_position = new_camera_position
		render_limit[0] += diff
		render_limit[1] += diff
		if render_limit[1] > render_position.x + instability_props["max_distance"]:
			render_platform()
		if platforms[0].position.x < render_limit[0]:
			platforms[0].queue_free()
			platforms.pop_front()
		var new_monsters = []
		for i in range(0, monsters.size()):
			if is_instance_valid(monsters[i]):
				new_monsters.push_front(monsters[i])
		monsters = new_monsters
		if not monsters.empty() and monsters[0].position.x < render_limit[0]:
			monsters[0].queue_free()
			monsters.pop_front()


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
	if instability_props.has("lightning_chance"):
		if lightning_timer < instability_props["lightning_frequency"]:
			lightning_timer += 1
		else:
			var lightning_appears = instability_props["lightning_chance"] < rand_range(0, 100)
			if lightning_appears:
				lightning_timer = 0
				var lightning = Lightning.instance()
				var is_accurate = rand_range(0, 100) <= lightning_accuracy
				if is_accurate:
					var target_index = randi() % (monsters.size() + 1)
					print(target_index)
					if target_index == monsters.size():
						print("target player")
						lightning.position = SceneManager.get_entity('Player').global_position
					elif is_instance_valid(monsters[target_index]):
						lightning.position = monsters[target_index].global_position
				else:
					print("target random")
					lightning.position = SceneManager.get_entity('Player').global_position
					lightning.position += Vector2(rand_range(-1000, 1000), rand_range(-300, -50))
				add_child(lightning)
