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

export (int) var max_mana = 1000
export (int) var mana_steps = 4
export (float) var mana_gather_factor = 10
export (float) var shield_time_threshold = 0.6
export (float) var digestion_factor = 1
export (float) var digestion_for_bullet = 10
export (float) var digestion_danger_threshold = 80
export (float) var shield_digestion_add = 5
export (float) var mana = 0
export (float) var dash_anim_duration = 0.2
export (float) var dash_speed_base = 1
export (float) var dash_stop = 0.1

var ExplosionAttack = preload('ExplosionAttack.tscn')

var Head = preload('BodyParts/Head.tscn')
var Torso = preload('BodyParts/Torso.tscn')
var Brazo = preload('BodyParts/Brazo.tscn')
var Brazo2 = preload('BodyParts/Brazo2.tscn')
var Pierna = preload('BodyParts/Pierna.tscn')
var Pierna2 = preload('BodyParts/Pierna2.tscn')

onready var hud = get_node(hud_path)
onready var smp = $StateMachinePlayer

var initial_jump_time = 10
var max_speed = max_speed_base
var acceleration = acceleration_base
var jump_speed = jump_speed_base / initial_jump_time
var dash_speed = dash_speed_base
var double_jump = false
var invincibility = false
var invincibility_counter = 0.0
var mana_level = 1
var jumping = false
var jump_time = 0
var last_shield_activation = 0.0
var shield_duration = 0.2
var digestion = 0
var was_shielding = false
var crouched = false
var digestion_danger = false
var time_between_mellee_shielded = 0.5
var last_melee_shielded = 0
var dash_timer = 0
var dash_direction = 1
var dash_jumped = false
var player_score = 0
var was_on_floor = false
var floor_timer = 0
var floor_time_sound = 0.4

var velocity = Vector2()

enum PlayerStates { ALIVE, DEAD }
var current_state = PlayerStates.ALIVE

var camera_limit = 2000

onready var jump_sounds = [$SoundJump1, $SoundJump2, $SoundJump3]
onready var double_jump_sounds = [$SoundDoubleJump1, $SoundDoubleJump2]
onready var damage_sounds = [$SoundDamage1, $SoundDamage2, $SoundDamage3]
onready var dash_texture = "res://Sprites/Runner_dash.png"
onready var dash_texture_flipped = "res://Sprites/Runner_dash_flipped.png"


# Called when the node enters the scene tree for the first time.
func _ready():
	hud.update_health(self.health)
	Globals.max_instability_level = mana_steps


func set_health(health):
	self.health = max(health, 0)
	if self.health <= 0:
		self.die()


func die():
	if current_state == PlayerStates.DEAD:
		return
	self.health = 0
	hud.update_health(self.health)
	self.current_state = PlayerStates.DEAD
	$Shield.get_node("CPUParticles2D").hide()
	$AnimatedSprite.hide()
	explode_body()
	velocity = Vector2()

	hud.player_is_dead()
	Globals.save_score(self.get_score(), hud.time_passed)
	yield(get_tree().create_timer(death_timer), "timeout")
	SceneManager.change_scene('res://MainMenu.tscn')


func explode_body():
	var head = Head.instance()
	var torso = Torso.instance()
	var pierna = Pierna.instance()
	var pierna2 = Pierna2.instance()
	var brazo = Brazo.instance()
	var brazo2 = Brazo2.instance()
	var body_parts = [head, torso, pierna, pierna2, brazo, brazo2]
	for part in body_parts:
		part.global_position = self.global_position
		var vector = Vector2(
			velocity.x + rand_range(-1, 1) * 200, velocity.y + rand_range(-1, -0.5) * 200
		)
		print(vector)
		part.apply_impulse(Vector2(), vector)
		SceneManager._current_scene.add_child(part)


func get_input():
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var crouch = Input.is_action_pressed('ui_down')
	var jump = Input.is_action_pressed('ui_select')
	var jump_just_pressed = Input.is_action_just_pressed('ui_select')
	var fire = Input.is_action_just_pressed('fire')
	var defend = Input.is_action_pressed('shield')
	var dash = Input.is_action_pressed('dash')

	if crouch and is_on_floor():
		smp.set_trigger('crouch')
	else:
		smp.set_trigger('stand_up')

	if dash and not (left and right) and (is_on_floor() or not dash_jumped):
		if abs(velocity.x) < max_speed:
			dash_direction = -1 if $AnimatedSprite.flip_h else 1
		if not is_on_floor():
			dash_jumped = true
		smp.set_trigger('start_dash')

	if (left or right) and not (left and right):
		if right and velocity.x < max_speed:
			velocity.x += acceleration
			if dash_direction == -1:
				dash_timer += dash_stop
		elif left and velocity.x > -max_speed:
			velocity.x -= acceleration
			if dash_direction == 1:
				dash_timer += dash_stop
	else:
		if velocity.x > 0:
			velocity.x = max(velocity.x - acceleration, 0)
		elif velocity.x < 0:
			velocity.x = min(velocity.x + acceleration, 0)
	if left:
		$AnimatedSprite.flip_h = left
	elif right:
		$AnimatedSprite.flip_h = false

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

	if fire:
		if mana > max_mana / mana_steps:
			$Camera2D.add_trauma(5)
			var explosion = ExplosionAttack.instance()
			explosion.global_position = global_position
			SceneManager._current_scene.add_child(explosion)
			mana -= max_mana / mana_steps
			$SoundExplosion.play()
		else:
			hud.show_not_enough_mana()
			$SoundCantShoot.play()

	if defend:
		if not was_shielding:
			$Shield.get_node("CPUParticles2D").restart()
			$Shield.get_node("CPUParticles2D").show()
			$Shield.get_node("CPUParticles2D").modulate.a = 1
		was_shielding = true
		self.delete_with_shield()
		last_shield_activation = 0
	elif shield_duration > last_shield_activation:
		$Shield.get_node("CPUParticles2D").modulate.a = (
			1
			- abs(shield_duration - last_shield_activation) / shield_duration
		)
		self.delete_with_shield()
	elif was_shielding:
		$Shield.get_node("CPUParticles2D").hide()
		was_shielding = false


func delete_with_shield():
	var targets = $Shield.get_overlapping_areas()
	for target in targets:
		if target.has_method('explode'):
			if not target.explode():  # if it explodes returns nothing
				self.add_digestion(digestion_for_bullet)
				$SoundShieldDeleteProjectile.play()


func add_digestion(dig):
	digestion += dig


func _on_StateMachinePlayer_transited(from, to):
	match to:
		"Run":
			$AnimatedSprite.play('Walk' if mana_level == 1 else 'Run')
		"Idle":
			$AnimatedSprite.play('Idle')
		"Jump":
			$AnimatedSprite.play('Jump')
			var num = randi() % jump_sounds.size()
			var sound = jump_sounds[num]
			sound.pitch_scale = 0.8 + randf() * 0.2 * Globals.instability_level
			jump_sounds[num].play()
			dash_jumped = false
		"DoubleJump":
			$AnimatedSprite.play('Jump')
			$AnimatedSprite.frame = 0
			print("double_jump")
			var num = randi() % double_jump_sounds.size()
			var sound = double_jump_sounds[num]
			sound.pitch_scale = 0.8 + randf() * 0.2 * Globals.instability_level
			double_jump_sounds[num].play()
		"Fall":
			$AnimatedSprite.play('Fall')
		"Crouch":
			$AnimatedSprite.play('Crouch')
			$CollisionShapeCrouched.disabled = false
			$CollisionShape2D.disabled = true
		"Death":
			$AnimatedSprite.hide()
		"Dash":
			$AnimatedSprite.play('Dash')
			$SoundDash.play()
			$Trail.emitting = true
			dash_timer = 0

	match from:
		"Crouch":
			$CollisionShapeCrouched.disabled = true
			$CollisionShape2D.disabled = false
		"Dash":
			$Trail.emitting = false
			$TrailFlipped.emitting = false


func _on_StateMachinePlayer_updated(state, delta):
	match state:
		"Fall":
			if is_on_floor():
				smp.set_trigger('land')
				double_jump = true
		"Crouch":
			velocity.x = 0
		"Dash":
			velocity.y = 0
			velocity.x += dash_direction * dash_speed
			dash_timer += delta
			if not $AnimatedSprite.flip_h:
				$Trail.emitting = true
				$TrailFlipped.emitting = false
			else:
				$Trail.emitting = false
				$TrailFlipped.emitting = true
			if dash_timer > dash_anim_duration:
				smp.set_trigger("end_dash")


func _physics_process(delta):
	if current_state == PlayerStates.DEAD:
		return
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))
	smp.set_param('h_speed', velocity.x)
	smp.set_param('v_speed', velocity.y)
	get_input()
	# check death by falling
	self.check_falling_death()
	self.process_invincibility(delta)
	last_shield_activation += delta
	last_melee_shielded += delta
	if was_shielding:
		self.add_digestion(delta * shield_digestion_add)
		$SoundShield.play()
	else:
		$SoundShield.stop()
	if not was_on_floor and is_on_floor() and floor_timer > floor_time_sound:
		$SoundFloorReached.play()
	floor_timer += delta
	was_on_floor = is_on_floor()


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


func mana_digestion(delta):
	if digestion:
		if digestion > digestion_danger_threshold:
			if not digestion_danger:
				digestion_danger = true
				$SoundDigestionDanger.play()
				SceneManager.get_entity('Level').change_music_volume(-6)
		else:
			digestion_danger = false
			$SoundDigestionDanger.stop()
			SceneManager.get_entity('Level').reset_music_volume()
		if digestion > 100:
			self.die()
		if self.mana != max_mana:
			digestion = max(digestion - delta * digestion_factor, 0)
			# self.mana += delta * digestion_factor  * (mana_steps - mana_level)
		hud.update_digestion(digestion)


func affect_mana(delta):
	var factor_affectation = mana_steps - mana_level
	factor_affectation = max(factor_affectation, 0.5)
	self.mana += delta * mana_gather_factor * factor_affectation

	self.mana_digestion(delta)
	self.mana = min(max_mana, self.mana)

	Globals.instability = mana * 100 / max_mana
	var mana_level_before = mana_level
	mana_level = floor(mana / max_mana * mana_steps) + 1
	Globals.instability_level = mana_level
	if mana_level_before < mana_level:
		$SoundInstabilityUp.play()

	max_speed = max_speed_base + pow(mana_level * mana_factor, 2)
	acceleration = acceleration_base + pow(mana_level * mana_factor, 2)
	jump_speed = (jump_speed_base - (mana_level * mana_factor)) / initial_jump_time
	dash_speed = dash_speed_base + pow(mana_level * mana_factor, 2)

	hud.update_mana(mana / max_mana)

	var mat = $AnimatedSprite.get_material()
	mat.set_shader_param("radius", (mana_level - 1) * 2)


func _process(delta):
	if $Camera2D.get_limit(MARGIN_LEFT) < $Camera2D.get_camera_position().x - camera_limit:
		$Camera2D.set_limit(MARGIN_LEFT, $Camera2D.get_camera_position().x - camera_limit)
	if current_state != PlayerStates.DEAD:
		affect_mana(delta)
		hud.update_health(self.health)
		hud.update_score(self.get_score())


func _on_hit(damage, damager):
	if not self.invincibility and self.current_state != PlayerStates.DEAD:
		if self.was_shielding:
			if last_melee_shielded < time_between_mellee_shielded:
				self.add_digestion(digestion_for_bullet)
				last_melee_shielded = 0
				$SoundShieldDefense.play()
		else:
			self.damage_sounds[randi() % self.damage_sounds.size()].play()
			self.set_health(self.health - damage)
			self.invincibility = true


func gain_points(points):
	self.player_score += points


func get_score():
	return player_score + ($Camera2D.get_limit(MARGIN_LEFT) + 1800) / 100
