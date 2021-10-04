extends CanvasLayer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play('fade')
	$AudioStreamPlayer.play()


func _on_AnimationPlayer_animation_finished(_animation_name):
	SceneManager.change_scene('res://MainMenu.tscn')
