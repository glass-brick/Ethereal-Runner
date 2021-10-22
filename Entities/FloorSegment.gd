extends RigidBody2D
signal platform_stepped

export (int) var expiration_time_base = 4
export (int) var expiration_speed = 1
export (bool) var indestructible = false
export (int) var max_monsters = 3
export (bool) var have_shader = true
var expiration_started = false
var expiration_time = expiration_time_base
var path_id
var platform_number
var color = Color.white


func _ready():
	$Sprite.modulate = color
	if have_shader:
		var mat = $Sprite.get_material()
		mat.set_shader_param("random_value", randf() * 2)
		mat.set_shader_param("frames", ceil(randf() * 5 + 2))
		mat.set_shader_param("speed", ceil(randf() * 5 + 2))


func _process(delta):
	if expiration_started:
		expiration_time -= delta * expiration_speed
		$Sprite.modulate.a = (
			min(expiration_time * expiration_speed, expiration_time_base)
			/ expiration_time_base
		)
	if expiration_time < 0:
		visible = false
		make_phaseable()


func start_expiration_timer(full_time = null):
	if full_time:
		self.expiration_time_base = full_time
		self.expiration_time = full_time
	expiration_started = true


func make_phaseable():
	collision_layer = 0
	collision_mask = 0


func _on_Player_grab_body_entered(body):
	emit_signal("platform_stepped", path_id, platform_number)
	if not indestructible:
		self.start_expiration_timer()
