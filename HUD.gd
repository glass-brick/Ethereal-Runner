extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var time_passed = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta
	update_time(time_passed)

func update_mana(mana):
	get_node("MainThings/Mana").text = "Mana: " + "%.0f" % mana

func update_time(time):
	get_node("MainThings/Time").text = "Time: " + "%.1f" % time + "s"

func update_distance(distance):
	get_node("MainThings/Distance").text = "Distance: " + distance

func update_health(health):
	get_node("MainThings/Health").text = "Health: " + str(health)
