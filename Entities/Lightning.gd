extends Area2D

export (int) var damage = 100


func _ready():
	$AnimatedSprite.play('default')


func _on_AnimatedSprite_frame_changed():
	if $AnimatedSprite.frame == 10:
		SoundManager.play_se('ThunderCrack')
		$CPUParticles2D.restart()
		var targets = get_overlapping_bodies()
		for target in targets:
			if target.has_method('_on_hit'):
				target._on_hit(damage, self)


func _on_AnimatedSprite_animation_finished():
	queue_free()
