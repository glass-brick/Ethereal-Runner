extends CanvasLayer

export (int) var message_fade_time = 2
export (float) var controls_opacity = 0.4

var message_timer = 0
var time_passed = 0
var menu_open = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$Controls.modulate.a = 0 if Globals.tutorial_finished else controls_opacity
	$Continue.hide()
	$NotEnoughMana.hide()
	$Digestion.value = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var paused = get_tree().paused
	if paused and not menu_open:
		# pause due to dialogue, dont do anything
		return
	if not paused:
		time_passed += delta
		update_time(time_passed)
	var pause = Input.is_action_just_pressed('pause')
	if pause:
		if not paused:
			self.pause()
		else:
			self.unpause()
	message_timer += delta
	$NotEnoughMana.modulate.a = 1.0 - message_timer / message_fade_time


func update_mana(mana):
	var manaBar = get_node("ManaBars")
	var bars = manaBar.get_children()
	var n_bars_complete = floor(mana * 4)
	for i in range(n_bars_complete):
		bars[i].value = 100
		bars[i].modulate.v = 0.7 + abs(cos(time_passed)) * 10 / 7
	if n_bars_complete < 4:
		bars[n_bars_complete].value = (mana - n_bars_complete / 4) * 400
		bars[n_bars_complete].modulate.v = 0.5
	for i in range(n_bars_complete + 1, 4):
		bars[i].value = 0
		bars[i].modulate.v = 0.5


func update_digestion(digestion):
	$Digestion.value = digestion


func update_time(time):
	var seconds = int(time) % 60
	var minutes = int((time - seconds) / 60)
	get_node("TimePanel/Time").text = "%02d:%02d" % [minutes, seconds]


func update_score(score):
	get_node("ScorePanel/Score").text = "Score\n%d" % score


func update_health(health):
	get_node("HealthBar").value = health


func player_is_dead(score):
	$DeathMsg.visible = true
	$DeathMsg.get_node("Score").text = "Score: %d" % score
	
	var body = to_json({"name": Globals.player_name, "points": score})
	var error = $HTTPRequest.request("{path}/submit_score".format({"path":Globals.leaderboards_server}), ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request.")



func pause():
	$Controls.modulate.a = 1
	$Continue.show()
	$Controls.show()
	get_tree().paused = true
	menu_open = true


func unpause():
	$Controls.modulate.a = 0 if Globals.tutorial_finished else controls_opacity
	$Continue.hide()
	$Controls.hide()
	get_tree().paused = false
	menu_open = false


func _on_Continue_pressed():
	unpause()


func show_not_enough_mana():
	message_timer = 0
	$NotEnoughMana.show()


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = parse_json(body.get_string_from_utf8())
		if json:
			print(json['status'])
			print(json['msg'])
			if json['msg'] == 'You made the top 10!':
				$DeathMsg.get_node("Leaderboard").show()
	else:
		print("Could not connect to server")

