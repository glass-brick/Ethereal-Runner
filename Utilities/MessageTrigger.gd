extends Area2D

export (String) var action = 'Jump'
export (String) var action_name = 'jump'


func _on_MessageTrigger_body_entered(body):
	if body == SceneManager.get_entity('Player'):
		var bindings = []
		for binding in InputMap.get_action_list(action_name):
			var friendly_name = OS.get_scancode_string(binding.get_scancode_with_modifiers())
			bindings.append(friendly_name)

		var friendly_action_name = (
			bindings[0]
			if bindings.size() == 1
			else '%s or %s' % [bindings[0], bindings[1]]
		)
		var text_to_show = 'Press %s to %s' % [friendly_action_name, action]
		SceneManager.get_entity('Level').show_overhead_message(text_to_show)
		queue_free()
