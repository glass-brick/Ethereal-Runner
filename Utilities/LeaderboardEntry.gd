extends HBoxContainer

export (Color) var focus_color = Color.blue
onready var default_color = $Name.get_color('font_color')


func _ready():
	visible = false


func set_entry(position, score, name):
	visible = true
	$Position.set_text('%s.' % position)
	$Score.set_text('[%s]' % score)
	$Name.set_text(name)
