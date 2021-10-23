extends Path2D

var started = false


func _ready():
	$PathFollow2D/AnimatedSprite.play('Idle')


func run_animation():
	started = true
	$PathFollow2D/AnimatedSprite.play('Run')


func _process(delta):
	if started:
		$PathFollow2D.unit_offset += delta
