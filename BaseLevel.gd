extends Node2D

var Platform = preload('res://FloorSegment.tscn')
var Monster = preload('res://Enemy1.tscn')
var Lightning = preload('res://Lightning.tscn')
onready var camera = $Player/Camera2D
onready var last_camera_position = camera.get_camera_screen_center()
var render_limit = [Vector2(-2000, -2000), Vector2(5000, 5000)]
var render_paths = [{"position": Vector2(0, 200), "biome": "normal", "id": randi(), "branch_on": 0}]
var time_passed = 0
var hue_value = 0
var new_path_frequency = 10
var new_path_height_diff = 400

var current_instability_level = 0

var biomes = {
	"normal": {"spawn_area": [Vector2(900, -50), Vector2(1200, 50)]},
	"falling": {"spawn_area": [Vector2(1100, 100), Vector2(1400, 200)]},
	"rising": {"spawn_area": [Vector2(800, -100), Vector2(1100, -200)]}
}

var instability_levels = [
	{
		"high_treshold": 1,
		"distance_modifier": 1,
		"monster_chance": 0,
	},
	{
		"high_treshold": 2,
		"distance_modifier": 1.2,
		"monster_chance": 20,
		"lightning_chance": 10,
		"lightning_frequency": 300,
	},
	{
		"low_treshold": 3,
		"high_treshold": 4,
		"distance_modifier": 1.4,
		"monster_chance": 40,
		"lightning_chance": 20,
		"lightning_frequency": 200,
	},
	{
		"low_treshold": 4,
		"distance_modifier": 1.6,
		"monster_chance": 60,
		"lightning_chance": 20,
		"lightning_frequency": 100,
	}
]

var platforms = []
var monsters = []
var platforms_rendered = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

	while render_paths[0]["position"].x < render_limit[1].x:
		render_platform()


func render_platform():
	platforms_rendered += 1
	for i in range(0, render_paths.size()):
		var biome_props = biomes[render_paths[i]["biome"]]
		var biome_spawn_area = biome_props["spawn_area"]
		var instability_props = instability_levels[current_instability_level]
		var platform = Platform.instance()
		platform.position = render_paths[i]["position"]
		platform.path_id = render_paths[i]["id"]
		platform.platform_number = platforms_rendered
		platform.connect("platform_stepped", self, "_on_platform_stepped")
		add_child(platform)
		platforms.push_back(platform)
		var spawn_monster = randi() % 100 <= instability_props["monster_chance"]
		if spawn_monster:
			var monster = Monster.instance()
			monster.position = render_paths[i]["position"]
			monster.position.y -= 300
			monster.path_id = render_paths[i]["id"]
			add_child(monster)
			monsters.push_back(monster)

		render_paths[i]["position"].x += (
			rand_range(biome_spawn_area[0].x, biome_spawn_area[1].x)
			* instability_props["distance_modifier"]
		)
		render_paths[i]["position"].y += (
			rand_range(biome_spawn_area[0].y, biome_spawn_area[1].y)
			* instability_props["distance_modifier"]
		)
		if Globals.last_y_platform < render_paths[i]["position"].y or i == render_paths.size() - 1:
			Globals.last_y_platform = render_paths[i]["position"].y


func _on_platform_stepped(path_id, platform_number):
	if (
		render_paths.size() > 1
		and render_paths[0]["branch_on"] != 0
		and render_paths[0]["branch_on"] <= platform_number
	):
		print('new path taken %d, number %d' % [path_id, platform_number])
		for platform in platforms:
			if platform.path_id != path_id:
				platform.start_expiration_timer()
				platform.make_phaseable()
		var new_paths = []
		for render_path in render_paths:
			if render_path["id"] == path_id:
				render_path["branch_on"] = 0
				new_paths.push_front(render_path)
		render_paths = new_paths
		for monster in monsters:
			if monster.path_id != path_id:
				monster.kill()


func _process(delta):
	process_platforms()
	change_instability_if_necessary()
	process_instability_effects()
	change_background_colors(delta)


func process_platforms():
	var new_camera_position = camera.get_camera_screen_center()
	if new_camera_position.x > last_camera_position.x:
		var diff = new_camera_position - last_camera_position
		last_camera_position = new_camera_position
		render_limit[0] += diff
		render_limit[1] += diff
		var should_render = false
		for render_path in render_paths:
			var spawn_area = biomes[render_path["biome"]]["spawn_area"]
			should_render = (
				should_render
				or render_limit[1].x > render_path["position"].x + spawn_area[0].x
			)
		if should_render:
			if platforms_rendered % new_path_frequency == 0:
				render_paths[0]["position"].y += new_path_height_diff
				render_paths[0]["branch_on"] = platforms_rendered + 1
				render_paths.push_back(
					{
						"position":
						Vector2(
							render_paths[0]["position"].x,
							render_paths[0]["position"].y - (new_path_height_diff * 2)
						),
						"biome": biomes.keys()[randi() % biomes.keys().size()],
						"id": randi(),
						"branch_on": platforms_rendered + 1
					}
				)
			render_platform()
		if platforms[0].position.x < render_limit[0].x:
			platforms[0].queue_free()
			platforms.pop_front()
		var new_monsters = []
		for i in range(0, monsters.size()):
			if is_instance_valid(monsters[i]):
				new_monsters.push_front(monsters[i])
		monsters = new_monsters
		if not monsters.empty() and monsters[0].position.x < render_limit[0].x:
			monsters[0].queue_free()
			monsters.pop_front()


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
					if target_index == monsters.size():
						lightning.position = SceneManager.get_entity('Player').global_position
					elif is_instance_valid(monsters[target_index]):
						lightning.position = monsters[target_index].global_position
				else:
					lightning.position = SceneManager.get_entity('Player').global_position
					lightning.position += Vector2(rand_range(-1000, 1000), rand_range(-300, -50))
				add_child(lightning)
