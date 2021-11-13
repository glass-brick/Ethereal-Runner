extends CanvasLayer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play('fade')
	$Music.play()


func _process(_delta):
	if Input.is_action_just_pressed('ui_accept') and not SceneManager.is_transitioning:
		SceneManager.change_scene('res://ContainerScenes/MainMenu.tscn')


func _on_AnimationPlayer_animation_finished(_animation_name):
	SceneManager.change_scene('res://ContainerScenes/MainMenu.tscn')


func _exit_tree():
	$Music.stop()
