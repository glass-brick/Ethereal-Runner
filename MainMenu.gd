extends CanvasLayer

var started = false
enum MenuStates { FREE_CURSOR, SELECTED_OPTION }
var current_state = MenuStates.FREE_CURSOR
var option_path = []
var focused_option_index = 0
onready var cursor = $Path2D
onready var current_menu = $MainMenu
var current_option = null


func _ready():
	$SettingsMenu.visible = false
	enter_menu($MainMenu)
	$Path2D/PathFollow2D/AnimatedSprite.play('Idle')
	var seconds = int(Globals.high_time) % 60
	var minutes = int((Globals.high_time - seconds) / 60)
	$HighScore.text = "High score: %d in %02d:%02d" % [Globals.high_score, minutes, seconds]


func _process(delta):
	if current_state == MenuStates.FREE_CURSOR:
		process_free_cursor()
	elif current_state == MenuStates.SELECTED_OPTION:
		process_selected_option()
	if started:
		$Path2D/PathFollow2D.unit_offset += delta


func process_selected_option():
	if Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed('ui_accept'):
		go_back()


func process_free_cursor():
	var focused_option = current_menu.get_child(focused_option_index)
	cursor.position = (
		current_menu.rect_position
		+ focused_option.rect_position
		+ Vector2(-20, focused_option.rect_size.y / 2)
	)

	if Input.is_action_just_pressed("ui_down"):
		focused_option_index = (focused_option_index + 1) % current_menu.get_child_count()
	elif Input.is_action_just_pressed("ui_up"):
		focused_option_index = (
			(focused_option_index - 1)
			if focused_option_index > 0
			else (current_menu.get_child_count() - 1)
		)

	if not started and Input.is_action_just_pressed('ui_accept'):
		select_option()
	if Input.is_action_just_pressed('ui_cancel'):
		go_back()


func select_option():
	print(option_path)
	var focused_option = current_menu.get_child(focused_option_index)
	var option_name = focused_option.name
	match option_name:
		"Tutorial":
			start_tutorial()
		"StartGame":
			start_game()
		"Settings":
			enter_menu($SettingsMenu)
		"BGMVolume":
			enter_slide_option(focused_option)
		"SFXVolume":
			enter_slide_option(focused_option)
		"ControlRemapping":
			pass


func enter_slide_option(slider):
	current_state = MenuStates.SELECTED_OPTION
	option_path.push_back(slider.name)
	current_option = slider
	current_option.selected = true


func go_back():
	if option_path.size() == 1:
		return
	current_state = MenuStates.FREE_CURSOR
	option_path.pop_back()
	if current_option:
		current_option.selected = false
		current_option = null
	else:
		var option_name = option_path[option_path.size() - 1]
		enter_menu(get_node(option_name))


func enter_menu(menu):
	option_path.push_back(menu.name)
	current_menu.visible = false
	menu.visible = true
	current_menu = menu
	focused_option_index = 0


func start_animation():
	$Path2D/PathFollow2D/AnimatedSprite.play('Run')
	started = true


func start_tutorial():
	start_animation()
	yield(get_tree().create_timer(1.0), "timeout")
	SceneManager.change_scene('res://TutorialLevel.tscn')


func start_game():
	start_animation()
	yield(get_tree().create_timer(1.0), "timeout")
	SceneManager.change_scene('res://BaseLevel.tscn')
