extends EditorProperty

var checkbox = CheckBox.new()
var current_cursor_menu = null
var CursorMenuScript = load("res://addons/cursor_menu/CursorMenu.gd")
var active = false


func _ready():
	current_cursor_menu = get_edited_object()

	label = "Show in editor"

	checkbox.connect("toggled", self, "_on_checkbox_checked")
	add_child(checkbox)


func _physics_process(_delta):
	if not current_cursor_menu and get_edited_object():
		current_cursor_menu = get_edited_object()
	checkbox.pressed = active


func _on_checkbox_checked(is_checked):
	if is_checked:
		activate(current_cursor_menu)
		var current_node = current_cursor_menu.get_parent()
		while is_cursor_menu(current_node):
			print(current_node)
			deactivate_only_options(current_node)
			current_node = current_node.get_parent()
		deactivate_sub_menus(current_cursor_menu)
		active = true
	else:
		deactivate(current_cursor_menu)
		active = false


func is_cursor_menu(node):
	return CursorMenuScript == node.get_script()


func activate(node):
	node.visible = true
	for child in node.get_children():
		if not is_cursor_menu(child):
			child.visible = true


func deactivate_only_options(node):
	for child in node.get_children():
		if not is_cursor_menu(child):
			child.visible = false


func deactivate(node):
	for child in node.get_children():
		if is_cursor_menu(child):
			deactivate(child)
		else:
			child.visible = false


func deactivate_sub_menus(node):
	for child in node.get_children():
		if is_cursor_menu(child):
			deactivate(child)


func check_is_active(node):
	for child in node.get_children():
		if not is_cursor_menu(child) and not child.visible:
			return false
	return true
