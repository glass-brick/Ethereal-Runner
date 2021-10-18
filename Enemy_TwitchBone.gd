extends KinematicBody2D

var Bullet = preload('res://Bullet.tscn')

onready var smp = $StateMachinePlayer

export (float) var death_time = 3
export (float) var max_length_shoot = 1600
export (int) var points = 50

var initial_time_to_attack = 400
var time_to_attack = 0

var initial_attack_time = 100
var attack_time = 0

var projectile_speed = 1000
var projectile_damage = 10
var projectile_range = 5000
var health = 1
var death_dissolution = 0
var path_id


func _on_StateMachinePlayer_transited(from, to):
	match to:
		"Idle":
			time_to_attack = initial_attack_time
			$AnimatedSprite.play("Idle")
		"Attack":
			attack_time = initial_attack_time
			$AnimatedSprite.play("Attack")
			shoot_projectile()
		"Dead":
			death_dissolution = 0.1  # for good measure
			$AnimatedSprite.play("Attack")
			$AnimatedSprite.set_material(load("res://Shader/EnemyDeathMaterial.tres"))


func shoot_projectile():
	SoundManager.play_se('TwitchBoneShoot')
	var projectile = Bullet.instance()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.projectile_range = projectile_range
	projectile.direction = (SceneManager.get_entity("Player").global_position - global_position).normalized()
	get_tree().get_root().add_child(projectile)
	projectile.position = position
	projectile.look_at(SceneManager.get_entity("Player").global_position)


func _on_StateMachinePlayer_updated(state, delta):
	match state:
		"Idle":
			$Arm.look_at(SceneManager.get_entity("Player").global_position)
			time_to_attack -= 1
			if (
				time_to_attack <= 0
				and (
					(SceneManager.get_entity("Player").global_position - self.global_position).length()
					< max_length_shoot
				)
			):
				smp.set_trigger('attack')
		"Attack":
			attack_time -= 1
			if attack_time <= 0:
				smp.set_trigger('attack_finished')
		"Dead":
			SoundManager.play_se('TwitchBoneDeath')
			death_dissolution += delta / death_time
			$AnimatedSprite.material.set_shader_param("effect_percentage", 1 - death_dissolution)


func _on_hit(damage, damager):
	if damager.has_method("gain_points"):
		damager.gain_points(self.points)
	set_health(health - damage)


func kill():
	set_health(0)


func set_health(new_health):
	health = max(new_health, 0)
	if health <= 0:
		smp.set_trigger('death')
		yield(get_tree().create_timer(death_time), "timeout")
		queue_free()


var velocity = Vector2(0, 0)
var gravity = 1200


func _physics_process(delta):
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))
