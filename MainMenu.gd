extends CanvasLayer

var started = false


func _process(delta):
	var seconds = int(Globals.high_time) % 60
	var minutes = int((Globals.high_time - seconds) / 60)
	$HighScore.text = "High score: %d in %02d:%02d" % [Globals.high_score, minutes, seconds]
	if not started and Input.is_action_just_pressed('ui_accept'):
		start_game()
	if started:
		$Path2D/PathFollow2D.unit_offset += delta


func _on_Button_button_down():
	start_game()


func start_game():
	$Path2D/PathFollow2D/AnimatedSprite.play('Run')
	started = true
	yield(get_tree().create_timer(1.0), "timeout")
	SceneManager.change_scene('res://BaseLevel.tscn')
