extends HBoxContainer

export (Color) var focus_color = Color.blue
onready var default_color = $Name.get_color('font_color')


func _ready():
	visible = false


func set_entry(position, score, name, time):
	visible = true
	$Position.set_text('%s.' % position)
	$Score.set_text('[%s]' % score)
	var seconds = int(time) % 60
	var minutes = int((time - seconds) / 60)
	var time_nice = "%02d:%02d" % [minutes, seconds]
	$Time.set_text('[%s]' % time_nice)
	$Name.set_text(name)
