extends CanvasLayer

export (int) var message_fade_time = 2

onready var pre_submit_menu = $DeathMenu/PreSubmitMenu
onready var submitting_label = $DeathMenu/SubmittingLabel
onready var post_submit_menu = $DeathMenu/PostSubmitMenu
onready var tutorial_death_menu = $DeathMenu/TutorialDeathMenu
onready var death_menu_steps = [
	pre_submit_menu,
	submitting_label,
	post_submit_menu,
	tutorial_death_menu,
]

var message_timer = 0
var time_passed = 0
var menu_open = false
var is_dead = false
var score = 0

var starter_names = [
	'Filthy Scum',
	'Worthless Pawn',
	'Abominable Human',
	'Human Garbage',
	'Hominid Parasite',
	"Embodiment of Suffering",
	"Flesh Automaton",
	"Lowest Common Denominator",
	"Deaf and Dumbstruck",
	"Rotting Head",
	"Cauldron of Hate",
	"Exhibit A of the Human Condition",
	"Perpetrator of Unauthorized Exploitation"
]


# Called when the node enters the scene tree for the first time.
func _ready():
	$PauseMenu.hide()
	$NotEnoughMana.hide()
	$DeathMenu.hide()
	$Digestion.value = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_dead:
		return
	var paused = get_tree().paused
	if paused and not menu_open:
		# pause due to dialogue, dont do anything
		return
	if not paused:
		time_passed += delta
		update_time(time_passed)
	var pause = Input.is_action_just_pressed('ui_cancel')
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


func update_score(_score):
	score = _score
	get_node("ScorePanel/Score").text = "Score\n%d" % score


func update_health(health):
	get_node("HealthBar").value = health


func player_is_dead():
	if SceneManager.get_entity("Level").is_tutorial:
		show_death_menu(tutorial_death_menu)
		return
	pre_submit_menu.get_node("Score").text = "Score: %d" % score
	is_dead = true
	if Globals.player_name:
		pre_submit_menu.get_node('NameInput').text = Globals.player_name
	else:
		randomize()
		var r = randi()
		var rand_number = r % len(starter_names)
		pre_submit_menu.get_node('NameInput').text = starter_names[rand_number]
	show_death_menu(pre_submit_menu)


func _on_Submit_pressed():
	Globals.player_name = pre_submit_menu.get_node('NameInput').text
	var body = to_json({"name": Globals.player_name, "points": score})
	var error = $HTTPRequest.request(
		"{path}/submit_score".format({"path": Globals.leaderboards_server}),
		["Content-Type: application/json", "User-Agent: EtherealRunner/1.0"],
		true,
		HTTPClient.METHOD_POST,
		body
	)
	if error != OK:
		post_submit_menu.get_node('Label').text = "Error submitting score"
		show_death_menu(post_submit_menu)
		push_error("An error occurred in the HTTP request.")
	else:
		show_death_menu(submitting_label)


func _on_RestartFromCheckpoint_pressed():
	SceneManager.reload_scene()


func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = parse_json(body.get_string_from_utf8())
		if json:
			post_submit_menu.get_node('Label').text = json['msg']
			show_death_menu(post_submit_menu)
	else:
		print("Could not connect to server")


func show_death_menu(step):
	$DeathMenu.show()
	for _step in death_menu_steps:
		if _step == step:
			_step.show()
			var child = find_focusable_child(_step)
			if child:
				child.grab_focus()
		else:
			_step.hide()


func pause():
	$PauseMenu.show()
	var child = find_focusable_child($PauseMenu)
	print(child)
	if child:
		child.grab_focus()

	get_tree().paused = true
	menu_open = true


func unpause():
	$PauseMenu.hide()
	get_tree().paused = false
	menu_open = false


func show_not_enough_mana():
	message_timer = 0
	$NotEnoughMana.show()


func _on_Return_pressed():
	unpause()


func _on_Quit_pressed():
	SceneManager.change_scene('res://ContainerScenes/MainMenu.tscn')
	yield(SceneManager, 'fade_complete')
	unpause()


func find_focusable_child(node):
	if node.focus_mode == 2:
		return node
	for child in node.get_children():
		if child.focus_mode == 2:
			return child
		else:
			var result = find_focusable_child(child)
			if result:
				return result
	return null
