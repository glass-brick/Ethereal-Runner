extends Node2D

export (float) var timer_expiration_non_taken_path = 1
export (float) var change_music_prob = 0.2

var TilePlatform = preload('res://Entities/TilePlatform.tscn')
var TwitchBone = preload('res://Entities/Enemy_TwitchBone.tscn')
var FleshStump = preload('res://Entities/Enemy_FleshStump.tscn')
var TreapanoGargoyle = preload('res://Entities/Enemy_TreapanoGargoyle.tscn')
var Lightning = preload('res://Entities/Lightning.tscn')
onready var camera = $Player/Camera2D
onready var last_camera_position = camera.get_camera_screen_center()
var render_limit = [Vector2(-2000, -2000), Vector2(5000, 5000)]
var render_paths = [{"position": Vector2(0, 200), "biome": "normal", "id": randi(), "branch_on": 0}]
var time_passed = 0
var hue_value = 0
var new_path_frequency = 10
var new_path_height_diff = 400
var songs = ['Vals', 'Inferno', 'NuevoMundo']
var current_music = null
var is_tutorial = false

var current_instability_level = 0

var biomes = {
	"normal":
	{
		"color": Color.white,
		"monsters": [TwitchBone],
		"spawn_area": [Vector2(900, -50), Vector2(1200, 50)],
		"platform_params":
		[
			{
				"type": "cloud",
				"size": 8,
				"max_monsters": 2,
				"weight": 10,
			},
			{
				"type": "cloud",
				"size": 5,
				"max_monsters": 1,
				"weight": 5,
			},
			{
				"type": "solid",
				"size": 5,
				"max_monsters": 0,
				"weight": 4,
			}
		],
		"weight": 9,
	},
	"falling":
	{
		"color": Color.lightpink,
		"monsters": [FleshStump, TreapanoGargoyle],
		"spawn_area": [Vector2(1100, 100), Vector2(1400, 200)],
		"platform_params":
		[
			{
				"type": "cloud",
				"size": 3,
				"max_monsters": 1,
				"weight": 6,
			},
			{
				"type": "cloud",
				"size": 6,
				"max_monsters": 2,
				"weight": 10,
			},
			{
				"type": "cloud",
				"size": 9,
				"max_monsters": 3,
				"weight": 3,
			},
		],
		"weight": 6,
	},
	"rising":
	{
		"color": Color.lightblue,
		"monsters": [TwitchBone, FleshStump],
		"spawn_area": [Vector2(800, -100), Vector2(1100, -200)],
		"platform_params":
		[
			{
				"type": "cloud",
				"size": 7,
				"max_monsters": 2,
				"weight": 8,
			},
			{
				"type": "cloud",
				"size": 4,
				"max_monsters": 1,
				"weight": 1,
			},
			{
				"type": "cloud",
				"size": 9,
				"max_monsters": 3,
				"weight": 1,
			}
		],
		"weight": 6,
	},
	"bad_boy":
	{
		"color": Color(0.3, 0.3, 0.3, 1),
		"monsters": [TreapanoGargoyle],
		"spawn_area": [Vector2(800, -100), Vector2(1100, -200)],
		"platform_params":
		[
			{
				"type": "cloud",
				"size": 6,
				"max_monsters": 2,
				"weight": 4,
			},
			{
				"type": "cloud",
				"size": 4,
				"max_monsters": 1,
				"weight": 1,
			},
			{
				"type": "cloud",
				"size": 8,
				"max_monsters": 3,
				"weight": 5,
			}
		],
		"weight": 1
	}
}

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

var platforms = []
var monsters = []
var platforms_rendered = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	change_music("Vals")

	while render_paths[0]["position"].x < render_limit[1].x:
		render_platform(true)


func set_platform(biome_props, path):
	var platform = TilePlatform.instance()
	var platform_key = choose_weighted_key(biome_props["platform_params"])
	var platform_params = biome_props["platform_params"][platform_key]

	platform.size = platform_params['size']
	platform.type = 'solid' if platforms_rendered == 1 else platform_params['type']
	platform.max_monsters = platform_params['max_monsters']

	platform.position = path["position"]
	platform.path_id = path["id"]
	platform.platform_number = platforms_rendered
	platform.color = biome_props["color"]
	platform.connect("platform_stepped", self, "_on_platform_stepped")
	add_child(platform)
	platforms.push_back(platform)
	return platform


func set_monsters(platform, biome_props, path, is_first_render):
	var instability_props = instability_levels[current_instability_level]
	var spawn_monster = (
		(not is_first_render)
		and randi() % 100 <= instability_props["monster_chance"]
	)
	if spawn_monster:
		var num_monsters
		if not "max_monsters_per_platform" in instability_props:
			num_monsters = 1
		else:
			num_monsters = (randi() % instability_props['max_monsters_per_platform']) + 1
			num_monsters = min(num_monsters, platform.max_monsters)

		for j in range(num_monsters):
			var monster_kind = biome_props["monsters"][randi() % biome_props["monsters"].size()]
			var monster = monster_kind.instance()
			var width = platform.width
			monster.position = path["position"]
			monster.position.x += (float(j + 1) / (num_monsters + 1) * width) - width / 2
			monster.position.y -= 300
			if monster.name == "TrepanoGargoyle":
				monster.position.y += monster.altitude
			monster.path_id = path["id"]
			add_child(monster)
			monsters.push_back(monster)


func advance_path_cursor(idx):
	var biome_spawn_area = biomes[render_paths[idx]["biome"]]["spawn_area"]
	var instability_props = instability_levels[current_instability_level]
	render_paths[idx]["position"].x += (
		rand_range(biome_spawn_area[0].x, biome_spawn_area[1].x)
		* instability_props["distance_modifier"]
	)
	render_paths[idx]["position"].y += (
		rand_range(biome_spawn_area[0].y, biome_spawn_area[1].y)
		* instability_props["distance_modifier"]
	)


func set_player_death_height(path_idx):
	if (
		Globals.last_y_platform < render_paths[path_idx]["position"].y
		or path_idx == render_paths.size() - 1
	):
		Globals.last_y_platform = render_paths[path_idx]["position"].y


func render_platform(is_first_render):
	platforms_rendered += 1
	for i in range(0, render_paths.size()):
		var biome_props = biomes[render_paths[i]["biome"]]
		var path = render_paths[i]
		var platform = set_platform(biome_props, path)
		set_monsters(platform, biome_props, path, is_first_render)
		advance_path_cursor(i)
		set_player_death_height(i)


func _on_platform_stepped(path_id, platform_number):
	if (
		render_paths.size() > 1
		and render_paths[0]["branch_on"] != 0
		and render_paths[0]["branch_on"] <= platform_number
	):
		for platform in platforms:
			if platform.path_id != path_id:
				platform.start_expiration_timer(timer_expiration_non_taken_path)
				platform.make_phaseable()
		var new_paths = []
		for render_path in render_paths:
			if render_path["id"] == path_id:
				render_path["branch_on"] = 0
				new_paths.push_front(render_path)
		render_paths = new_paths
		for monster in monsters:
			if is_instance_valid(monster) and monster.path_id != path_id:
				monster.kill()

		var random_number = randf()
		if true or random_number < change_music_prob:
			if Globals.instability_level > 2:
				change_music("Inferno")
			else:
				var poss_songs = ['Vals', 'NuevoMundo']
				change_music(poss_songs[randi() % poss_songs.size()])


func _process(delta):
	process_platforms()
	change_instability_if_necessary()
	process_instability_effects()
	change_background_colors(delta)


func choose_weighted_key(dict):
	var is_array = dict is Array
	var total_weight = 0
	for value in dict if is_array else dict.values():
		total_weight += value['weight']
	var weight_passed = 0
	var random_num = randf() * total_weight
	for key in range(dict.size()) if is_array else dict.keys():
		weight_passed += dict[key]['weight']
		if random_num < weight_passed:
			return key
	return randi() % dict.size if is_array else dict.keys()[randi() % dict.keys().size()]


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
				render_paths[0]["biome"] = choose_weighted_key(biomes)
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
			render_platform(false)
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
	parallaxLayer1.modulate.h = hue_value
	parallaxLayer1.modulate.s = sat


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
				var is_accurate = rand_range(0, 100) <= min(100, monsters.size() * 10)
				if is_accurate:
					var target_index = randi() % (monsters.size() + 1)
					if target_index == monsters.size():
						lightning.position = SceneManager.get_entity('Player').global_position
					elif is_instance_valid(monsters[target_index]):
						lightning.position = monsters[target_index].global_position
				else:
					lightning.position = SceneManager.get_entity('Player').global_position
					lightning.position += Vector2(
						rand_range(400, 1600) * ((randi() % 2) * 2 - 1), rand_range(-600, -200)
					)
				add_child(lightning)

export (int) var fade_in_time = 15
export (int) var fade_out_time = 15

func change_music(name):
	if self.current_music == name:
		return
	if self.current_music:
		fade_out(self.current_music)
	self.current_music = name
	fade_in(self.current_music)

func fade_out(name):
	var tween = Tween.new()
	self.add_child(tween)
	tween.interpolate_property(SoundManager.get_audiostream(name), "volume_db", Globals.bgm_volume, Globals.bgm_volume - 80, fade_out_time, Tween.TRANS_CIRC, Tween.EASE_OUT_IN, 0)
	tween.connect("tween_completed", self, "_on_TweenOut_tween_completed")
	tween.start()

func fade_in(name):
	var tween = Tween.new()
	self.add_child(tween)
	SoundManager.play_bgm(name)
	tween.interpolate_property(SoundManager.get_audiostream(name), "volume_db", Globals.bgm_volume - 80, Globals.bgm_volume, fade_in_time, Tween.TRANS_EXPO, Tween.EASE_OUT, 0)
	tween.connect("tween_completed", self, "_on_TweenIn_tween_completed")
	tween.start()

func _on_TweenIn_tween_completed(object, key):
	print("tween completed")

func _on_TweenOut_tween_completed(object, key):
	object.stop()


func _exit_tree():
	SoundManager.stop(current_music)
