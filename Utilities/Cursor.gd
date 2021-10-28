extends Control

var started = false


func _ready():
	$Path2D/PathFollow2D/AnimatedSprite.play('Idle')


func run_animation():
	started = true
	$Path2D/PathFollow2D/AnimatedSprite.play('Run')


func _process(delta):
	if started:
		$Path2D/PathFollow2D.unit_offset += delta
