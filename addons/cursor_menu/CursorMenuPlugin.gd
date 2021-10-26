tool
extends EditorPlugin

var plugin


func _enter_tree():
	add_custom_type("CursorMenu", "Control", preload("CursorMenu.gd"), preload('icon.svg'))
	plugin = load("res://addons/cursor_menu/CursorInspectorPlugin.gd").new()
	add_inspector_plugin(plugin)


func _exit_tree():
	remove_custom_type("CursorMenu")
	remove_inspector_plugin(plugin)
