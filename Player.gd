extends KinematicBody2D

export (int) var max_speed = 400
export (int) var acceleration = 50
export (int) var jump_speed = -600
export (int) var gravity = 1200
export (int) var health = 100

export (int) var invincibility_time = 2
export (float) var blinking_speed = 0.05

var velocity = Vector2()

enum PlayerStates { ALIVE, DEAD }
var current_state = PlayerStates.ALIVE

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_health(health):
	self.health = max(health, 0)

func get_input():
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_just_pressed('ui_select')

	if (left or right) and not (left and right):
		if right and velocity.x < max_speed:
			velocity.x += acceleration
		elif left and velocity.x > -max_speed:
			velocity.x -= acceleration
	else:
		if velocity.x > 0:
			velocity.x = max(velocity.x - acceleration, 0)
		elif velocity.x < 0:
			velocity.x = min(velocity.x + acceleration, 0)
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	if jump	and is_on_floor():
		velocity.y = jump_speed

func _physics_process(delta):
	self.velocity.y += gravity * delta
	self.velocity = move_and_slide(velocity, Vector2(0, -1))
	if not current_state == PlayerStates.DEAD:
		self.get_input()


