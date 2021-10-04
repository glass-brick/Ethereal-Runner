extends Area2D

export (String) var timeline_name = 'Welcome'


func _on_DialogueTrigger_body_entered(body):
	if body == SceneManager.get_entity('Player'):
		SceneManager.get_entity('Level').start_dialogue(timeline_name)
		queue_free()
