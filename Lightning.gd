extends Area2D

var damage = 100


func _ready():
	$AnimatedSprite.play('default')


func _on_AnimatedSprite_animation_finished():
	queue_free()


func _on_AnimatedSprite_frame_changed():
	if $AnimatedSprite.frame == 5:
		var targets = get_overlapping_bodies()
		print(targets)
		for target in targets:
			if target.has_method('_on_hit'):
				target._on_hit(damage, self)
