extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var initial_time_to_attack = 200
var time_to_attack = 0

var initial_attack_time = 5
var attack_time = 0


func _on_StateMachinePlayer_transited(from, to):
	match to:
		"Idle":
			time_to_attack = initial_attack_time
		"Attack":
			attack_time = initial_attack_time


func _on_StateMachinePlayer_updated(state, delta):
	match state:
		"Idle":
			time_to_attack -= 1
		"Attack":
			attack_time -= 1
