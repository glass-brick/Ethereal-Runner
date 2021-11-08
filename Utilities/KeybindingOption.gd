extends Control

export (String) var action_name = ""

onready var action_label = $Label
onready var instruction_label = $HBoxContainer/PressAKey
onready var main_key = $HBoxContainer/MainKey
onready var secondary_key = $HBoxContainer/SecondaryKey

var selected_key_idx = null


func _ready():
	action_label.text = action_name.capitalize()
	main_key.text = get_action_key(0)
	secondary_key.text = get_action_key(1)
	instruction_label.visible = false


func get_action_key(idx):
	var bindings = InputMap.get_action_list(action_name)
	if bindings.size() <= idx:
		return "[ Unset ]"
	return OS.get_scancode_string(bindings[idx].get_scancode_with_modifiers())


func _on_MainKey_pressed():
	start_key_change(0)


func _on_SecondaryKey_pressed():
	start_key_change(1)


func start_key_change(idx):
	instruction_label.visible = true
	main_key.visible = false
	secondary_key.visible = false
	selected_key_idx = idx


func finish_key_change():
	instruction_label.visible = false
	main_key.visible = true
	secondary_key.visible = true
	main_key.text = get_action_key(0)
	secondary_key.text = get_action_key(1)
	if selected_key_idx == 1:
		main_key.grab_focus()
	else:
		secondary_key.grab_focus()
	selected_key_idx = null
	Globals.save_game()


func _input(event):
	if event is InputEventKey and selected_key_idx != null and event.is_pressed():
		get_tree().set_input_as_handled()
		if event.scancode == KEY_ESCAPE:
			finish_key_change()
			return

		var bindings = InputMap.get_action_list(action_name)
		InputMap.action_erase_events(action_name)
		for i in range(bindings.size()):
			if i == selected_key_idx:
				bindings[i] = event
		if bindings.size() == selected_key_idx:  # if it's a new key
			bindings.append(event)

		for binding in bindings:
			InputMap.action_add_event(action_name, binding)
		finish_key_change()
