extends Area2D

export (int) var damage = 10
export (int) var speed = 40
export (int) var projectile_range = 400

var direction
var distance_made = 0
var exploding = false


func _ready():
	$AnimatedSprite.play()


func _physics_process(delta):
	if exploding:
		return
	self.position += self.direction * self.speed * delta
	distance_made += (self.direction * self.speed * delta).length()
	if distance_made > projectile_range:
		queue_free()


func _on_Bullet_body_entered(body):
	if body.has_method('_on_hit'):
		body._on_hit(self.damage, self)
	self.explode()
	
func explode():
	if exploding:
		return true
	exploding = true
	queue_free()
