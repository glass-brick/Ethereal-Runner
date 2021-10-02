extends CanvasLayer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var time_passed = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta
	update_time(time_passed)


func update_mana(mana):
	get_node("ManaBar").value = mana


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
