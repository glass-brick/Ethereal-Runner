extends KinematicBody2D

export (float) var death_time = 3
export (float) var initial_time_to_attack = 2
export (int) var points = 50

onready var smp = $StateMachinePlayer

var time_to_attack = 0

var initial_attack_time = 30
var attack_time = 0
var player_detected = false
var attack_range = 400

var flipped = false

var initial_time_to_flip = 10
var time_to_flip = 0

var damage = 20
var speed = 300
var health = 1
var death_dissolution = 0
var path_id

var velocity = Vector2(0, 0)
var gravity = 1200
var attack_frame = false


func _on_AnimatedSprite_frame_changed():
	attack_frame = $AnimatedSprite.frame == 1 and $AnimatedSprite.animation == "Attack"


func _on_StateMachinePlayer_transited(from, to):
	match from:
		"Attack":
			time_to_attack = initial_time_to_attack
		"Run":
			velocity.x = 0
	match to:
		"Idle":
			$AnimatedSprite.play("Idle")
		"Attack":
			attack_time = initial_attack_time
			$AnimatedSprite.play("Attack")
			time_to_flip = 0
		"Run":
			$AnimatedSprite.play("Run")
		"Dead":
			death_dissolution = 0.1  # for good measure
			$AnimatedSprite.play("Idle")
			$AnimatedSprite.set_material(load("res://Assets/Shader/EnemyDeathMaterial.tres"))


func _on_StateMachinePlayer_updated(state, delta):
	match state:
		"Run":
			var target = SceneManager.get_entity('Player').global_position
			if time_to_flip > 0:
				time_to_flip -= 1
			else:
				var should_flip = flipped != (target.x > global_position.x)
				if should_flip:
					flipped = not flipped
					time_to_flip = initial_time_to_flip
					global_scale.x = -1 if flipped else 1
			velocity.x = speed * (1 if flipped else -1)
			velocity = move_and_slide(velocity, Vector2(0, -1))
			if time_to_attack > 0:
				time_to_attack -= delta
			elif abs(target.x - global_position.x) < attack_range:
				smp.set_trigger('attack')
		"Attack":
			if not attack_frame:
				return
			var targets = $AttackHitbox.get_overlapping_bodies()
			for target in targets:
				if target == SceneManager.get_entity("Player") and target.has_method('_on_hit'):
					target._on_hit(damage, self)
			attack_time -= 1
			if attack_time <= 0:
				smp.set_trigger('attack_finished')
		"Dead":
			death_dissolution += delta / death_time
			$AnimatedSprite.material.set_shader_param("effect_percentage", 1 - death_dissolution)


func _on_DetectionArea_body_entered(body):
	if body == SceneManager.get_entity('Player'):
		player_detected = true


func _on_DetectionArea_body_exited(body):
	if body == SceneManager.get_entity('Player'):
		player_detected = false


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


func _physics_process(delta):
	smp.set_param('player_detected', player_detected)
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))
