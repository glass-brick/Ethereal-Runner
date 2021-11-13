extends KinematicBody2D

onready var smp = $StateMachinePlayer

export (float) var death_time = 3
export (int) var jump_speed = -900
export (int) var points = 50

export (Dictionary) var initial_timers = {
	"air_hold": 30,
	"attack": 30,
}

onready var ground_hurtbox = $GroundHurtbox
onready var air_hurtbox = $AirHurtbox
onready var dive_hurtbox = $DiveHurtbox
onready var hurtboxes = [ground_hurtbox, air_hurtbox, dive_hurtbox]

var timers = initial_timers.duplicate()

var damage = 20
var health = 1
var death_dissolution = 0
var path_id
var flipped = false
var player_detected = true

var velocity = Vector2(0, 0)
var gravity = 3200


func process_timer(key):
	timers[key] -= 1
	if timers[key] <= 0:
		timers[key] = initial_timers[key]
		return true
	return false


func set_hurtbox(hurtbox_to_set):
	for hurtbox in hurtboxes:
		if hurtbox == hurtbox_to_set:
			hurtbox.disabled = false
		else:
			hurtbox.disabled = true


func _on_StateMachinePlayer_transited(_from, to):
	match to:
		"Idle":
			$AnimatedSprite.play("idle")
			set_hurtbox(ground_hurtbox)
		"Jump":
			$AnimatedSprite.play("jump")
		"AirHold":
			$AnimatedSprite.play("air_hold")
		"Morph":
			$AnimatedSprite.play("morph")
		"Dive":
			set_hurtbox(dive_hurtbox)
			$AnimatedSprite.play("dive")
			var direction_vector = (
				SceneManager.get_entity('Player').global_position
				- global_position
			).normalized()
			velocity = direction_vector * 1000
		"Attack":
			$AnimatedSprite.play("attack")
		"Dead":
			death_dissolution = 0.1  # for good measure
			$AnimatedSprite.playing = false
			$AnimatedSprite.set_material(load("res://Assets/Shader/EnemyDeathMaterial.tres"))
			yield(get_tree().create_timer(death_time), "timeout")
			queue_free()


func _on_PlayerDetectionArea_body_entered(body):
	if body == SceneManager.get_entity('Player'):
		smp.set_trigger('jump')


func _on_StateMachinePlayer_updated(state, delta):
	match state:
		"Idle":
			velocity.y += gravity * delta
		"AirHold":
			velocity = lerp(velocity, Vector2(0, 0), 10 * delta)
			var is_time_to_morph = process_timer("air_hold")
			if is_time_to_morph:
				smp.set_trigger("morph")
		"Morph":
			look_at(SceneManager.get_entity('Player').global_position)
			rotation_degrees += 180
			var direction_vector = (
				SceneManager.get_entity('Player').global_position
				- global_position
			).normalized()
			var should_flip = flipped != (direction_vector.x > 0)
			if should_flip:
				flipped = not flipped
				global_scale.x *= -1
		"Dive":
			var is_time_to_attack = process_timer("attack")
			if is_time_to_attack:
				smp.set_trigger("start_attack")
			var targets = $AttackHitbox.get_overlapping_bodies()
			for target in targets:
				if target == SceneManager.get_entity("Player") and target.has_method('_on_hit'):
					target._on_hit(damage, self)
		"Attack":
			velocity = lerp(velocity, Vector2(0, 0), delta)
			var targets = $AttackHitbox.get_overlapping_bodies()
			for target in targets:
				if target == SceneManager.get_entity("Player") and target.has_method('_on_hit'):
					target._on_hit(damage, self)
		"Dead":
			velocity = lerp(velocity, Vector2(0, 0), delta)
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
		smp.set_trigger('death')


func _physics_process(_delta):
	velocity = move_and_slide(velocity, Vector2(0, -1))


func _on_AnimatedSprite_frame_changed():
	if $AnimatedSprite.animation == "jump" and $AnimatedSprite.frame == 3:
		velocity.y = jump_speed
		set_hurtbox(air_hurtbox)


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "jump":
		smp.set_trigger("finish_jump")
	elif $AnimatedSprite.animation == "morph":
		smp.set_trigger("dive")
	elif $AnimatedSprite.animation == "attack":
		smp.set_trigger("finish_attack")
