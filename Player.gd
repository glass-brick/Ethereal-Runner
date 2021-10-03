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

export (int) var max_mana = 1000
export (int) var mana_steps = 10
export (float) var mana_gather_factor = 10
export (float) var shield_time_threshold = 0.6

var ExplosionAttack = preload('ExplosionAttack.tscn')

onready var hud = get_node(hud_path)
onready var smp = $StateMachinePlayer

var mana = 0
var initial_jump_time = 10
var max_speed = max_speed_base
var acceleration = acceleration_base
var jump_speed = jump_speed_base / initial_jump_time
var double_jump = false
var invincibility = false
var invincibility_counter = 0.0
var mana_level = 1
var jumping = false
var jump_time = 0
var last_shield_activation = 0.0
var shield_duration = 0.2

var velocity = Vector2()

enum PlayerStates { ALIVE, DEAD }
var current_state = PlayerStates.ALIVE

var camera_limit = 2000


# Called when the node enters the scene tree for the first time.
func _ready():
	hud.update_health(self.health)
	Globals.max_instability_level = mana_steps


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
	Globals.save_score(($Camera2D.get_limit(MARGIN_LEFT) + 1800) / 100, hud.time_passed)
	yield(get_tree().create_timer(death_timer), "timeout")
	SceneManager.change_scene('res://MainMenu.tscn')


func get_input():
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_pressed('ui_select')
	var jump_just_pressed = Input.is_action_just_pressed('ui_select')
	var fire = Input.is_action_just_pressed('fire')
	var defend = Input.is_action_just_pressed('shield')

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
	$AnimatedSprite.flip_h = left

	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	if jump_just_pressed and (is_on_floor() or double_jump):
		smp.set_trigger('jump')
		jumping = true
		jump_time = initial_jump_time
		velocity.y = jump_speed * initial_jump_time
		if not is_on_floor():
			double_jump = false

	if jump_time > 0:
		if not jump:
			velocity.y -= jump_time * jump_speed
			jump_time = 0
			jumping = false
		else:
			jump_time -= 1
			if jump_time == 0:
				jumping = false

	if fire and mana > explosion_cost:
		var explosion = ExplosionAttack.instance()
		explosion.global_position = global_position
		SceneManager._current_scene.add_child(explosion)
		mana = 0

	if defend and last_shield_activation > shield_time_threshold :
		$Shield.get_node("CPUParticles2D").restart()
		self.delete_with_shield()
		last_shield_activation = 0
	if shield_duration > last_shield_activation:
		self.delete_with_shield()

func delete_with_shield():
	var targets = $Shield.get_overlapping_areas()
	for target in targets:
		if (target.has_method('explode')):
			target.explode()

func _on_StateMachinePlayer_transited(from, to):
	match to:
		"Run":
			$AnimatedSprite.play('Run')
		"Idle":
			$AnimatedSprite.play('Idle')
		"Jump":
			$AnimatedSprite.play('Jump')
		"DoubleJump":
			$AnimatedSprite.play('Jump')
			$AnimatedSprite.frame = 0
		"Fall":
			$AnimatedSprite.play('Fall')


func _on_StateMachinePlayer_updated(state, delta):
	match state:
		"Fall":
			if is_on_floor():
				smp.set_trigger('land')
				double_jump = true


func _physics_process(delta):
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))
	smp.set_param('h_speed', velocity.x)
	smp.set_param('v_speed', velocity.y)
	if not current_state == PlayerStates.DEAD:
		get_input()
	# check death by falling
	self.check_falling_death()
	self.process_invincibility(delta)
	last_shield_activation += delta


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


func affect_mana(delta):
	mana += delta * mana_gather_factor
	Globals.instability = mana * 100 / max_mana
	mana_level = floor(mana / max_mana * mana_steps) + 1
	Globals.instability_level = mana_level

	max_speed = max_speed_base + pow(mana_level * mana_factor, 2)
	acceleration = acceleration_base + pow(mana_level * mana_factor, 2)
	jump_speed = (jump_speed_base - (mana_level * mana_factor)) / initial_jump_time

	hud.update_mana(mana / max_mana)

	var mat = $AnimatedSprite.get_material()
	mat.set_shader_param("radius", mana_level - 1)


func _process(delta):
	if $Camera2D.get_limit(MARGIN_LEFT) < $Camera2D.get_camera_position().x - camera_limit:
		$Camera2D.set_limit(MARGIN_LEFT, $Camera2D.get_camera_position().x - camera_limit)
	affect_mana(delta)
	hud.update_health(self.health)
	hud.update_score(($Camera2D.get_limit(MARGIN_LEFT) + 1800) / 100)


func _on_hit(damage, damager):
	if not self.invincibility and self.current_state != PlayerStates.DEAD:
		self.set_health(self.health - damage)
		self.invincibility = true
