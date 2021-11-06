tool

extends Node2D
signal platform_stepped(path_id, platform_number)

export (String, "cloud", "solid") var type = "cloud"
export (int) var size = 2

var path_id
var platform_number
var indestructible = false

var max_monsters = 3

var expiration_time_base = 4
var expiration_speed = 1
var expiration_started = false
var expiration_time = expiration_time_base
var color = Color.white
var width = 0
var area_padding = 50
onready var tileset = $Tileset


func _ready():
	match type:
		"cloud":
			make_cloud_platform(size)
		"solid":
			make_solid_platform(size)


func make_cloud_platform(_size: int):
	modulate = color
	var mat = tileset.get_material()
	mat.set_shader_param("random_value", randf() * 2)
	mat.set_shader_param("frames", ceil(randf() * 5 + 2))
	mat.set_shader_param("speed", ceil(randf() * 5 + 2))

	make_platform(0, _size, 1)


func make_solid_platform(_size: int):
	make_platform(1, _size, 1)
	indestructible = true


func make_tiled_solid_platform(_size_x: int, _size_y: int):
	make_platform(2, _size_x, _size_y)
	indestructible = true


func make_platform(_type: int, _size_x: int, _size_y: int):
	tileset.clear()
	for child in get_children():
		if child != tileset:
			child.queue_free()
	var current_x = 0
	while current_x < _size_x:
		var current_y = 0
		while current_y < _size_y:
			tileset.set_cell(current_x, current_y, _type)
			current_y += 1
		current_x += 1
	tileset.update_bitmask_region(Vector2(0, 0), Vector2(_size_x, _size_y))

	var end_position = tileset.map_to_world(Vector2(_size_x, 0)) * tileset.scale
	tileset.position.x = -end_position.x / 2
	width = end_position.x

	var player_grab_shape = RectangleShape2D.new()
	player_grab_shape.extents = Vector2(end_position.x / 2 - area_padding, 10)
	var player_grab_collision_shape = CollisionShape2D.new()
	player_grab_collision_shape.shape = player_grab_shape
	var player_grab_area = Area2D.new()
	player_grab_area.add_child(player_grab_collision_shape)
	add_child(player_grab_area)
	player_grab_area.collision_layer = 0
	player_grab_area.collision_mask = 1
	player_grab_area.connect("body_entered", self, "_on_Player_grab_body_entered")


var prev_size = size
var prev_type = type


func _process(delta):
	if Engine.editor_hint:
		if type != prev_type or size != prev_size:
			prev_size = size
			prev_type = type
			_ready()
		return

	if expiration_started:
		expiration_time -= delta * expiration_speed
		modulate.a = (
			min(expiration_time * expiration_speed, expiration_time_base)
			/ expiration_time_base
		)
	if expiration_time < 0:
		visible = false
		make_phaseable()


func make_phaseable():
	tileset.collision_layer = 0
	tileset.collision_mask = 0


func start_expiration_timer(full_time = null):
	if full_time:
		self.expiration_time_base = full_time
		self.expiration_time = full_time
	expiration_started = true


func _on_Player_grab_body_entered(_body):
	emit_signal("platform_stepped", path_id, platform_number)
	if not indestructible:
		start_expiration_timer()
