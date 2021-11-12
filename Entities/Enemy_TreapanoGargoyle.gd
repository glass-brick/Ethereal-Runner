extends KinematicBody2D

var Bullet = preload('res://Entities/GargBullet.tscn')

onready var smp = $StateMachinePlayer

export (float) var death_time = 3
export (float) var max_length_shoot = 2600
export (int) var projectile_speed = 2600
export (int) var projectile_damage = 10
export (int) var projectile_range = 5000
export (float) var initial_attack_time = 2
export (float) var time_attack_shoot = 0.6
export (int) var speed = 100
export (int) var points = 300

var time_to_attack = 0
var altitude = -700

var attack_time = 0

var health = 1
var death_dissolution = 0
var path_id
var flipped = false
var time_to_flip = 1
var flip_timer = 0
var fire_now = false


func _on_StateMachinePlayer_transited(from, to):
	match to:
		"Fly":
			time_to_attack = initial_attack_time
			$AnimatedSprite.play("fly")
		"Fire":
			attack_time = initial_attack_time
			$AnimatedSprite.play("attack")
		"Dead":
			death_dissolution = 0.1  # for good measure
			$AnimatedSprite.set_material(load("res://Assets/Shader/EnemyDeathMaterial.tres"))
			yield(get_tree().create_timer(death_time), "timeout")
			queue_free()


func shoot_projectile():
	var projectile = Bullet.instance()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.projectile_range = projectile_range
	projectile.direction = (SceneManager.get_entity("Player").global_position - global_position).normalized()
	projectile.look_at(SceneManager.get_entity("Player").global_position)
	get_tree().get_root().add_child(projectile)
	projectile.position = position
	SoundManager.play_se('GargoyleShoot')


func _on_StateMachinePlayer_updated(state, delta):
	match state:
		"Fly":
			velocity.x = speed * (1 if flipped else -1)
			velocity = move_and_slide(velocity, Vector2(0, -1))
			if (
				time_to_attack <= 0
				and (
					(SceneManager.get_entity("Player").global_position - self.global_position).length()
					< max_length_shoot
				)
			):
				smp.set_trigger('start_firing')
			time_to_attack -= delta
			flip_timer += delta
			if flip_timer > time_to_flip:
				flipped = not flipped
		"Fire":
			if fire_now:
				shoot_projectile()
				fire_now = false
			attack_time -= delta
			if attack_time <= 0:
				smp.set_trigger('stop_firing')
		"Dead":
			death_dissolution += delta / death_time
			$AnimatedSprite.material.set_shader_param("effect_percentage", 1 - death_dissolution)


func _on_hit(damage, damager):
	if damager.has_method("gain_points"):
		damager.gain_points(self.points)
		AchievementManager.progress_achievement("50_kills", 1)
	set_health(health - damage)


func kill():
	set_health(0)


func set_health(new_health):
	health = max(new_health, 0)
	if health <= 0:
		smp.set_trigger('die')


var velocity = Vector2(0, 0)
var gravity = 1200


func _physics_process(delta):
	# velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))


func _on_AnimatedSprite_frame_changed():
	if $AnimatedSprite.animation == ("attack") and $AnimatedSprite.frame == 4:
		fire_now = true
