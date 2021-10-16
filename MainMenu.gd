extends CanvasLayer

var started = false


func _ready():
	$Path2D/PathFollow2D/AnimatedSprite.play('Idle')
	$HTTPRequest.request("https://ethereal-runner-server.gggelo.repl.co/leaderboard")


func _process(delta):
	$Button.text = (
		"Press space to start"
		if Globals.tutorial_finished
		else "Press space to play tutorial"
	)
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
	SceneManager.change_scene(
		'res://BaseLevel.tscn' if Globals.tutorial_finished else 'res://TutorialLevel.tscn'
	)


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = parse_json(body.get_string_from_utf8())
		if json:
			for i in json.keys():
				if not json[i]:
					continue
				var name = json[i].get('name','')
				var points = json[i].get('points','')
				var node = "Leaderboard/VBoxContainer/Pos{}".format([i], "{}")
				get_node(node).text = "[{}] {}".format([points, name], "{}")
	else:
		get_node("Leaderboard/VBoxContainer/Pos0").text = "Could not connect to server"
