extends CanvasLayer

var time_passed = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	$Controls.hide()
	$Continue.hide()
	$Digestion.value = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var paused = get_tree().paused
	if not paused:
		time_passed += delta
		update_time(time_passed)
	var pause = Input.is_action_just_pressed('pause')
	if pause:
		if not paused:
			self.pause()
		else:
			self.unpause()


func update_mana(mana):
	var manaBar = get_node("ManaBars")
	var bars = manaBar.get_children()
	var n_bars_complete = floor(mana * 4)
	for i in range(n_bars_complete):
		bars[i].value = 100
		bars[i].modulate.v = 0.7 + abs(cos(time_passed))*10/7
	if n_bars_complete < 4:
		bars[n_bars_complete].value = (mana - n_bars_complete / 4) * 400
		bars[n_bars_complete].modulate.v = 0.5 
	for i in range(n_bars_complete+1,4):
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


func player_is_dead():
	$DeathMsg.visible = true


func pause():
	$Continue.show()
	$Controls.show()
	get_tree().paused = true


func unpause():
	$Continue.hide()
	$Controls.hide()
	get_tree().paused = false


func _on_Continue_pressed():
	unpause()
