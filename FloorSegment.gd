extends RigidBody2D

export (int) var expiration_time_base = 4
export (int) var expiration_speed = 1
var expiration_started = false
var expiration_time = expiration_time_base

func _ready():
	pass # Replace with function body.

func _process(delta):
	if expiration_started:
		expiration_time -= delta * expiration_speed
		$Sprite.modulate.r = (expiration_time_base - expiration_time)/expiration_time_base
		$Sprite.modulate.g = (expiration_time_base - expiration_time)/expiration_time_base
		$Sprite.modulate.b = (expiration_time_base - expiration_time)/expiration_time_base
	if expiration_time < 0:
		queue_free()


func start_expiration_timer():
	expiration_started = true
	

func _on_Player_grab_body_entered(body):
	self.start_expiration_timer()
