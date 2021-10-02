extends Node2D

var Platform = preload('res://FloorSegment.tscn')
var Monster = preload('res://Enemy1.tscn')
onready var camera = $Player/Camera2D
onready var last_camera_position = camera.get_camera_screen_center().x
var render_limit = [-2000, 5000]
var render_position = Vector2(0, 200)

var current_instability_level = 0

var instability_levels = [
	{
		"high_treshold": 20,
		"min_distance": 800,
		"max_distance": 1100,
		"max_height_diff": 50,
		"min_height_diff": 150,
		"monster_chance": 0,
	},
	{
		"low_treshold": 20,
		"high_treshold": 40,
		"min_distance": 900,
		"max_distance": 1200,
		"max_height_diff": 100,
		"min_height_diff": 150,
		"monster_chance": 20,
	},
	{
		"low_treshold": 40,
		"high_treshold": 60,
		"min_distance": 1100,
		"max_distance": 1400,
		"max_height_diff": 120,
		"min_height_diff": 200,
		"monster_chance": 80,
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


func _process(delta):
	var new_camera_position = camera.get_camera_screen_center().x
	var instability_props = instability_levels[current_instability_level]
	if new_camera_position > last_camera_position:
		print(render_limit)
		var diff = new_camera_position - last_camera_position
		last_camera_position = new_camera_position
		render_limit[0] += diff
		render_limit[1] += diff
		if render_limit[1] > render_position.x + instability_props["max_distance"]:
			render_platform()
		if platforms[0].position.x < render_limit[0]:
			platforms[0].queue_free()
			platforms.pop_front()
		if not monsters.empty() and monsters[0].position.x < render_limit[0]:
			monsters[0].queue_free()
			monsters.pop_front()
	if (
		instability_props.has("high_treshold")
		and instability_props["high_treshold"] < Globals.instability
	):
		current_instability_level += 1
	elif (
		instability_props.has("low_treshold")
		and instability_props["low_treshold"] > Globals.instability
	):
		current_instability_level -= 1
