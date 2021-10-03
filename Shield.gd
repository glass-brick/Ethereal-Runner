extends Area2D


func _ready():
	$CPUParticles2D.restart()


var hit_targets = []


func _process(delta):
	var targets = get_overlapping_bodies()
	print(targets)
	for target in targets:
		if (target.has_method('explode')):
			target.explode()
			hit_targets.push_back(target)
		elif hit_targets.has(target):
			print("hit_targets.has(target)")
		elif target == SceneManager.get_entity("Player"):
			print("SceneManager")
		elif target.has_method('explode'):
			print("target.has_method('explode')")
