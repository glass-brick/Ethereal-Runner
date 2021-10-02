extends Area2D

var damage = 100


func _ready():
	$CPUParticles2D.restart()


var hit_targets = []


func _process(delta):
	var targets = get_overlapping_bodies()
	for target in targets:
		if (
			not hit_targets.has(target)
			and not target == SceneManager.get_entity("Player")
			and target.has_method('_on_hit')
		):
			target._on_hit(damage, self)
			hit_targets.push_back(target)
