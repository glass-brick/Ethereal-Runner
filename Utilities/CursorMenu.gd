extends Control
signal selected_option(option, menu)
signal option_changed(option, menu)

export (PackedScene) var cursor_scene = null
export (bool) var is_active = true
export (bool) var extend_cursor_to_children = true

var focused_option_index = 0
var is_root_menu = true
var cursor = null
var menu_options = []
var sub_menus = []
var selected_option = null

var selectable_option_types = [Range]


func _ready():
	is_root_menu = not get_parent().has_meta('is_cursor_menu')  # Cambiar por type cuando se arme el plugin
	if cursor_scene:
		set_cursor(cursor_scene)
	if is_active and is_root_menu:
		activate()
	else:
		set_options()


func set_options():
	for menu_option in get_children():
		if menu_option.has_meta('is_cursor_menu'):
			sub_menus.append(menu_option)
			menu_option.connect('selected_option', self, '_on_submenu_selected_option')
			menu_option.connect('option_changed', self, '_on_submenu_option_changed')
			menu_option.deactivate()
		else:
			menu_options.append(menu_option)
			menu_option.visible = true


func set_cursor(_cursor_scene):
	cursor_scene = _cursor_scene
	cursor = cursor_scene.instance()


func activate():
	visible = true
	is_active = true
	menu_options = []
	set_options()
	add_child(cursor)


func deactivate():
	is_active = false
	for menu_option in menu_options:
		menu_option.visible = false
	remove_child(cursor)


func open_menu(menu_name):
	for sub_menu in sub_menus:
		if sub_menu.name == menu_name:
			if extend_cursor_to_children:
				sub_menu.set_cursor(cursor_scene)
			sub_menu.call_deferred('activate')
			deactivate()
			return
	push_error('Menu not found: ' + menu_name)


func _process(_delta):
	var focused_option = get_child(focused_option_index)
	if cursor:
		cursor.position = (
			focused_option.rect_position
			+ Vector2(-20, focused_option.rect_size.y / 2)
		)

	if not is_active:
		return
	if selected_option:
		process_selected_option()
	else:
		process_free_cursor()


func process_selected_option():
	# TODO: add more Control types, and separate this logic from the CursorMenu somehow
	if selected_option is Range:
		if Input.is_action_just_pressed('ui_left'):
			selected_option.set_value(selected_option.value - selected_option.step)
		if Input.is_action_just_pressed('ui_right'):
			selected_option.set_value(selected_option.value + selected_option.step)

		emit_signal('option_changed', selected_option, self)

		if Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('ui_accept'):
			call_deferred('set_selected_option', null)


func process_free_cursor():
	if Input.is_action_just_pressed("ui_down"):
		focused_option_index = (focused_option_index + 1) % menu_options.size()
	elif Input.is_action_just_pressed("ui_up"):
		focused_option_index = (
			(focused_option_index - 1)
			if focused_option_index > 0
			else (menu_options.size() - 1)
		)

	if Input.is_action_just_pressed('ui_accept'):
		select_option()
	if Input.is_action_just_pressed('ui_cancel'):
		go_back()


func go_back():
	if is_root_menu:
		return
	get_parent().call_deferred('activate')
	deactivate()


func set_selected_option(option):
	selected_option = option


func select_option():
	var focused_option = menu_options[focused_option_index]

	emit_signal('selected_option', focused_option, self)

	for selectable_option_type in selectable_option_types:
		if focused_option is selectable_option_type:
			call_deferred('set_selected_option', focused_option)
			break

	if focused_option.has_method('on_option_selected'):
		focused_option.call_deferred('on_option_selected')
	else:
		push_error(
			(
				"Selected option (%s) does not have an 'on_option_selected' method"
				% focused_option.name
			)
		)


# Repeat signals so we can hook directly to the root
func _on_submenu_option_changed(option, menu):
	emit_signal('option_changed', option, menu)


func _on_submenu_selected_option(option, menu):
	emit_signal('selected_option', option, menu)
