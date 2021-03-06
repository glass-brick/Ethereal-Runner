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

var Head = preload('res://Entities/BodyParts/Head.tscn')
var Torso = preload('res://Entities/BodyParts/Torso.tscn')
var Brazo = preload('res://Entities/BodyParts/Brazo.tscn')
var Brazo2 = preload('res://Entities/BodyParts/Brazo2.tscn')
var Pierna = preload('res://Entities/BodyParts/Pierna.tscn')
var Pierna2 = preload('res://Entities/BodyParts/Pierna2.tscn')

onready var hud = get_node(hud_path)
onready var smp = $StateMachinePlayer

var mana_level_stats = [
	{  # este no deberia salir nunca, pero necesitamos el index 0 y si lo mando vacio explota
		"max_speed": 600,
		"acceleration": 100,
		"jump_speed": -900,
		"dash_speed": 1500,
		"mana_gather_speed_multiplier": 7
	},
	{
		"max_speed": 600,
		"acceleration": 100,
		"jump_speed": -900,
		"dash_speed": 1500,
		"mana_gather_speed_multiplier": 7
	},
	{
		"max_speed": 700,
		"acceleration": 200,
		"jump_speed": -1000,
		"dash_speed": 1600,
		"mana_gather_speed_multiplier": 4
	},
	{
		"max_speed": 800,
		"acceleration": 300,
		"jump_speed": -1100,
		"dash_speed": 1900,
		"mana_gather_speed_multiplier": 3
	},
	{
		"max_speed": 900,
		"acceleration": 400,
		"jump_speed": -1300,
		"dash_speed": 2200,
		"mana_gather_speed_multiplier": 2
	},
	{
		"max_speed": 1000,
		"acceleration": 500,
		"jump_speed": -1500,
		"dash_speed": 2500,
		"mana_gather_speed_multiplier": 1
	}
]

var jump_regulation_frames = 10
var max_speed = mana_level_stats[0]["max_speed"]
var acceleration = mana_level_stats[0]["acceleration"]
var jump_speed = mana_level_stats[0]["jump_speed"]
var dash_speed = mana_level_stats[0]["dash_speed"]

var can_double_jump = false
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

var achievement_trackers = {
	"points_while_no_explosions": 0,
	"max_mana_time": 0,
}

# load all sounds
onready var jump_sound_names = [$Sounds/Jump1, $Sounds/Jump2, $Sounds/Jump3]
onready var double_jump_sound_names = [$Sounds/DoubleJump1, $Sounds/DoubleJump2]
onready var damage_sound_names = [$Sounds/Damage1, $Sounds/Damage2, $Sounds/Damage3]
onready var jump_sounds = [$Sounds/Jump1, $Sounds/Jump2, $Sounds/Jump3]
onready var double_jump_sounds = [$Sounds/DoubleJump1, $Sounds/DoubleJump2]
onready var damage_sounds = [$Sounds/Damage1, $Sounds/Damage2, $Sounds/Damage3]


# Called when the node enters the scene tree for the first time.
func _ready():
	hud.update_health(self.health)
	Globals.max_instability_level = mana_steps

	# # set sounds
	# for name in jump_sound_names:
	# 	jump_sounds.append($Sounds.get_node(name))
	# for name in double_jump_sound_names:
	# 	double_jump_sounds.append($Sounds.get_node(name))
	# for name in damage_sound_names:
	# 	damage_sounds.append($Sounds.get_node(name))
			

func set_health(health):
	self.health = max(health, 0)
	if self.health <= 0:
		self.die()


func die():
	if current_state == PlayerStates.DEAD:
		return
	AchievementManager.progress_achievement('death', 1)
	self.health = 0
	hud.update_health(self.health)
	self.current_state = PlayerStates.DEAD
	$Shield.get_node("CPUParticles2D").hide()
	$AnimatedSprite.hide()
	explode_body()
	velocity = Vector2()

	hud.player_is_dead()
	Globals.save_score(self.get_score(), hud.time_passed)


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
		var vector = Vector2(rand_range(-1, 1) * 200, rand_range(-1, -0.5) * 200)
		part.apply_impulse(Vector2(), vector)
		SceneManager._current_scene.add_child(part)
	$DeathBloodEffect.emitting = true


func get_input():
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var crouch = Input.is_action_pressed('ui_down')
	var jump = Input.is_action_pressed('jump')
	var jump_just_pressed = Input.is_action_just_pressed('jump')
	var fire = Input.is_action_just_pressed('fire')
	var defend = Input.is_action_pressed('shield')
	var dash = Input.is_action_pressed('dash')

	if is_on_floor():
		dash_jumped = false
		can_double_jump = true

	if crouch and is_on_floor():
		smp.set_trigger('crouch')
	else:
		smp.set_trigger('stand_up')

	if dash and not (left and right) and (is_on_floor() or not dash_jumped):
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

	if jump_just_pressed and (is_on_floor() or can_double_jump):
		smp.set_trigger('jump')
		jumping = true
		jump_time = jump_regulation_frames
		velocity.y = jump_speed
		if not is_on_floor():
			can_double_jump = false

	if jump_time > 0:
		if not jump:
			velocity.y -= jump_speed * jump_time / jump_regulation_frames
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
			achievement_trackers['points_while_no_explosions'] = self.get_score()
			$Sounds/Explosion.play()
		else:
			hud.show_not_enough_mana()
			$Sounds/CantShoot.play()

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
				$Sounds/ShieldDeleteProjectile.play()


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
			sound.play()
			dash_jumped = false
		"DoubleJump":
			$AnimatedSprite.play('Jump')
			$AnimatedSprite.frame = 0
			var num = randi() % double_jump_sounds.size()
			var sound = double_jump_sounds[num]
			sound.pitch_scale = 0.8 + randf() * 0.2 * Globals.instability_level
			sound.play()
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
			$Sounds/Dash.play()
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
		$Sounds/Shield.play()
	else:
		$Sounds/Shield.stop()
	if not was_on_floor and is_on_floor() and floor_timer > floor_time_sound:
		$Sounds/FloorReached.play()
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
				$Sounds/DigestionDanger.play()
				hud.shield_overloading()
				# SceneManager.get_entity('Level').change_music_volume(-6)
		else:
			digestion_danger = false
			$Sounds/DigestionDanger.stop()
			hud.stop_shield_overloading()
			# SceneManager.get_entity('Level').reset_music_volume()
		if digestion > 100:
			self.die()
		if self.mana != max_mana:
			digestion = max(digestion - delta * digestion_factor, 0)
			# self.mana += delta * digestion_factor  * (mana_steps - mana_level)
		hud.update_digestion(digestion)


func affect_mana(delta):
	var gather_multiplier = mana_level_stats[mana_level]['mana_gather_speed_multiplier']
	self.mana += delta * mana_gather_factor * gather_multiplier

	self.mana_digestion(delta)
	self.mana = min(max_mana, self.mana)

	Globals.instability = mana * 100 / max_mana
	var mana_level_before = mana_level
	mana_level = floor(mana / max_mana * mana_steps) + 1
	Globals.instability_level = mana_level
	if mana_level_before < mana_level:
		$Sounds/InstabilityUp.play()

	max_speed = mana_level_stats[mana_level]['max_speed']
	acceleration = mana_level_stats[mana_level]['acceleration']
	jump_speed = mana_level_stats[mana_level]['jump_speed']
	dash_speed = mana_level_stats[mana_level]['dash_speed']

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
	check_achievements(delta)


func check_achievements(delta):
	for key in ["5k_points","10k_points","15k_points"]:
		if AchievementManager.get_achievement(key)["points_required"] <= self.get_score():
			AchievementManager.unlock_achievement(key)
	if self.get_score() - achievement_trackers["points_while_no_explosions"] >= AchievementManager.get_achievement("3k_points_no_explosions")["points_required"]:
		AchievementManager.unlock_achievement("3k_points_no_explosions")

	achievement_trackers["max_mana_time"] = achievement_trackers["max_mana_time"] + delta if mana >= max_mana else 0
	if achievement_trackers["max_mana_time"] >= AchievementManager.get_achievement("max_mana_30_secs")["time_required"]:
		AchievementManager.unlock_achievement("max_mana_30_secs")


func _on_hit(damage, damager):
	if not self.invincibility and self.current_state != PlayerStates.DEAD:
		if self.was_shielding:
			if last_melee_shielded < time_between_mellee_shielded:
				self.add_digestion(digestion_for_bullet)
				last_melee_shielded = 0
				$Sounds/ShieldDefenseMelee.play()
		else:
			self.set_health(self.health - damage)
			if self.current_state == PlayerStates.DEAD:
				$Sounds/PlayerDeath.play()
			else:
				damage_sounds[randi() % damage_sounds.size()].play()
			self.invincibility = true


func gain_points(points):
	self.player_score += points


func get_score():
	return player_score + ($Camera2D.get_limit(MARGIN_LEFT) + 1800) / 100
