extends CanvasLayer

var time_passed = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	$Controls.hide()
	$Continue.hide()
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta
	update_time(time_passed)

func _physics_process(delta):
	var pause = Input.is_action_just_pressed('pause')
	if pause:
		self.pause()


func update_mana(mana):
	var manaBar = get_node("ManaBar")
	manaBar.value = mana * 100
	manaBar.self_modulate = Color(1,1,1,mana/2+0.5)


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

func stop_pause():
	$Continue.hide()
	$Controls.hide()
	get_tree().paused = false


func _on_Continue_pressed():
	stop_pause()
