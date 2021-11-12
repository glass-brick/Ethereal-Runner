extends Area2D

var damage = 100


func _ready():
	$CPUParticles2D.restart()


var hit_targets = []


func _process(delta):
	if not $CPUParticles2D.emitting:
		queue_free()
	if hit_targets.size() == 4:
		AchievementManager.unlock_achievement("four_monsters_one_explosion")
	var targets = get_overlapping_bodies()
	for target in targets:
		if (
			not hit_targets.has(target)
			and not target == SceneManager.get_entity("Player")
			and target.has_method('_on_hit')
		):
			target._on_hit(damage, SceneManager.get_entity("Player"))
			hit_targets.push_back(target)
