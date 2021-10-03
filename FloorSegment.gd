extends RigidBody2D
signal platform_stepped

export (int) var expiration_time_base = 4
export (int) var expiration_speed = 1
export (bool) var test = false
var expiration_started = false
var expiration_time = expiration_time_base
var path_id
var platform_number


func _ready():
	print(path_id)
	var mat = $Sprite.get_material()
	mat.set_shader_param("random_value", randf() * 2)
	mat.set_shader_param("frames", ceil(randf() * 5 + 2))
	mat.set_shader_param("speed", ceil(randf() * 5 + 2))


func _process(delta):
	if expiration_started:
		expiration_time -= delta * expiration_speed
		$Sprite.modulate.r = expiration_time / expiration_time_base
		$Sprite.modulate.g = expiration_time / expiration_time_base
		$Sprite.modulate.b = expiration_time / expiration_time_base
		$Sprite.modulate.a = (
			min(expiration_time * expiration_speed, expiration_time_base)
			/ expiration_time_base
		)
	if expiration_time < 0:
		visible = false
		collision_layer = 0
		collision_mask = 0


func start_expiration_timer():
	expiration_started = true


func _on_Player_grab_body_entered(body):
	if not test:
		emit_signal("platform_stepped", path_id, platform_number)
		self.start_expiration_timer()
