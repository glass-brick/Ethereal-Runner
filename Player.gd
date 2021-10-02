extends KinematicBody2D

export (int) var max_speed_base = 400
export (int) var acceleration_base = 50
export (int) var jump_speed_base = -1000
export (int) var gravity = 3200
export (int) var health = 100
export (float) var death_timer = 2.0
export (float) var fall_death_distance = 3000
# mana_factor is how much max_speed, acceleratiorn and jump_speed are affected
# by mana
export (float) var mana_factor = 1

export (float) var invincibility_time = 0.5
export (float) var blinking_speed = 0.05
export (NodePath) var hud_path
export (int) var explosion_cost = 5

var ExplosionAttack = preload('ExplosionAttack.tscn')

onready var hud = get_node(hud_path)

var mana = 0
var max_speed = max_speed_base
var acceleration = acceleration_base
var jump_speed = jump_speed_base
var invincibility = false
var invincibility_counter = 0.0

var velocity = Vector2()

enum PlayerStates { ALIVE, DEAD }
var current_state = PlayerStates.ALIVE

var camera_limit = 2000


# Called when the node enters the scene tree for the first time.
func _ready():
	hud.update_health(self.health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_health(health):
	self.health = max(health, 0)
	if self.health <= 0:
		self.die()


func die():
	self.health = 0
	self.current_state = PlayerStates.DEAD
	hud.player_is_dead()
	yield(get_tree().create_timer(death_timer), "timeout")
	SceneManager.reload_scene()


func get_input():
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_just_pressed('ui_select')
	var fire = Input.is_action_just_pressed('fire')

	if (left or right) and not (left and right):
		if right and velocity.x < max_speed:
			velocity.x += acceleration
		elif left and velocity.x > -max_speed:
			velocity.x -= acceleration
	else:
		if velocity.x > 0:
			velocity.x = max(velocity.x - acceleration, 0)
		elif velocity.x < 0:
			velocity.x = min(velocity.x + acceleration, 0)
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	if jump and is_on_floor():
		velocity.y = jump_speed

	if fire and mana > explosion_cost:
		var explosion = ExplosionAttack.instance()
		explosion.global_position = global_position
		SceneManager._current_scene.add_child(explosion)
		mana = 0


func _physics_process(delta):
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))
	if not current_state == PlayerStates.DEAD:
		get_input()
	# check death by falling
	self.check_falling_death()
	self.process_invincibility(delta)


func process_invincibility(delta):
	if self.invincibility:
		invincibility_counter += delta
		var mat = $AnimatedSprite.get_material()
		mat.set_shader_param("active", true)
		if invincibility_counter > self.invincibility_time:
			self.invincibility = false
	else:
		invincibility_counter = 0
		var mat = $AnimatedSprite.get_material()
		mat.set_shader_param("active", false)


func check_falling_death():
	if self.global_position.y > Globals.last_y_platform + fall_death_distance:
		self.die()


func affect_mana():
	max_speed = max_speed_base + (mana * mana_factor) * (mana * mana_factor)
	acceleration = acceleration_base + (mana * mana_factor) * (mana * mana_factor)
	jump_speed = jump_speed_base - (mana * mana_factor)


func _process(delta):
	if $Camera2D.get_limit(MARGIN_LEFT) < $Camera2D.get_camera_position().x - camera_limit:
		$Camera2D.set_limit(MARGIN_LEFT, $Camera2D.get_camera_position().x - camera_limit)
	mana += delta
	affect_mana()
	hud.update_mana(mana)
	hud.update_health(self.health)
	hud.update_score(($Camera2D.get_limit(MARGIN_LEFT) + 1800) / 100)
	Globals.instability = mana


func _on_hit(damage, damager):
	if not self.invincibility and self.current_state != PlayerStates.DEAD:
		print("me pega")
		self.set_health(self.health - damage)
		self.invincibility = true

