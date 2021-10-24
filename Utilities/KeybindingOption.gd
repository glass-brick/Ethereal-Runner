extends Control

export (String) var action_name = ""

var selected = false


func _ready():
	$Label.text = action_name.capitalize()
	$Button.text = get_action_key()


func get_action_key():
	return OS.get_scancode_string(
		InputMap.get_action_list(action_name)[0].get_scancode_with_modifiers()
	)


func on_option_selected():
	print('selected!')
	$PressAKey.visible = true
	$Button.visible = false
	get_parent().lock()
	selected = true


func _input(event):
	if event is InputEventKey and selected and event.pressed:
		print('change key!')
		$PressAKey.visible = false
		$Button.visible = true
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)
		$Button.text = get_action_key()
		selected = false
		yield(get_tree().create_timer(0.0), 'timeout')  # necessary for ui_accept to not trigger instantly if key is space
		get_parent().unlock()
