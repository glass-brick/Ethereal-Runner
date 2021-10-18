extends CanvasLayer

var started = false

onready var cursor = $Path2D
onready var current_menu = $MainMenu
var focused_option = 0


func _ready():
	open_menu($MainMenu)
	$Path2D/PathFollow2D/AnimatedSprite.play('Idle')
	var seconds = int(Globals.high_time) % 60
	var minutes = int((Globals.high_time - seconds) / 60)
	$HighScore.text = "High score: %d in %02d:%02d" % [Globals.high_score, minutes, seconds]


func _process(delta):
	var current_option = current_menu.get_child(focused_option)
	cursor.position = (
		current_menu.rect_position
		+ current_option.rect_position
		+ Vector2(-20, current_option.rect_size.y / 2)
	)

	if Input.is_action_just_pressed("ui_down"):
		focused_option = (focused_option + 1) % current_menu.get_child_count()
	elif Input.is_action_just_pressed("ui_up"):
		focused_option = (
			(focused_option - 1)
			if focused_option > 0
			else (current_menu.get_child_count() - 1)
		)

	if not started and Input.is_action_just_pressed('ui_accept'):
		select_option()
	if started:
		$Path2D/PathFollow2D.unit_offset += delta
	if Input.is_action_just_pressed('ui_cancel'):
		if current_menu != $MainMenu:
			open_menu($MainMenu)


func select_option():
	var option_text = current_menu.get_child(focused_option).text
	match option_text:
		"Tutorial":
			start_tutorial()
		"Start Game":
			start_game()
		"Settings":
			open_menu($SettingsMenu)


func open_menu(menu):
	current_menu.visible = false
	menu.visible = true
	current_menu = menu
	focused_option = 0


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
