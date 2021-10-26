extends EditorInspectorPlugin

var CursorMenuScript = load("res://addons/cursor_menu/CursorMenu.gd")
var VisibilityProperty = load('res://addons/cursor_menu/MenuVisibilityOption.gd')


func can_handle(object):
	var script = object.get_script()
	return script and script == CursorMenuScript


func parse_category(object, category):
	if category == "Script Variables":
		add_property_editor("visible_in_editor", VisibilityProperty.new())
		return true
	return false
