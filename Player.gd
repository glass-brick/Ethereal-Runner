extends KinematicBody2D

export (int) var max_speed_base = 400
export (int) var acceleration_base = 50
export (int) var jump_speed_base = -1000
export (int) var gravity = 3200
export (int) var health = 100
# mana_factor is how much max_speed, acceleratiorn and jump_speed are affected
# by mana
export (float) var mana_factor = 1

export (int) var invincibility_time = 2
export (float) var blinking_speed = 0.05
export (NodePath) var hud_path

onready var hud = get_node(hud_path)

var mana = 0
var max_speed = max_speed_base
var acceleration = acceleration_base
var jump_speed = jump_speed_base

var velocity = Vector2()

enum PlayerStates { ALIVE, DEAD }
var current_state = PlayerStates.ALIVE

var camera_limit = 2000


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_health(health):
	health = max(health, 0)


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

	if jump and is_on_floor():
		velocity.y = jump_speed


func _physics_process(delta):
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))
	if not current_state == PlayerStates.DEAD:
		get_input()


func affect_mana():
	max_speed = max_speed_base + (mana * mana_factor) * (mana * mana_factor)
	acceleration = acceleration_base + (mana * mana_factor) * (mana * mana_factor)
	jump_speed = jump_speed_base - (mana * mana_factor)


func _process(delta):
	if $Camera2D.get_limit(MARGIN_LEFT) < $Camera2D.get_camera_position().x - camera_limit:
		$Camera2D.set_limit(MARGIN_LEFT, $Camera2D.get_camera_position().x - camera_limit)
	mana += delta
	affect_mana()
	hud.update_mana(mana)
	Globals.instability = mana
