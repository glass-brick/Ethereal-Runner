extends HBoxContainer

export (Color) var focus_color = Color.blue
onready var default_color = $Name.get_color('font_color')


func _ready():
	connect('focus_entered', self, '_on_focus_entered')
	connect('focus_exited', self, '_on_focus_exited')
	visible = false


func set_entry(position, score, name):
	visible = true
	$Position.set_text('%s.' % position)
	$Score.set_text('[%s]' % score)
	$Name.set_text(name)


func _on_focus_entered():
	$Name.add_color_override('font_color', focus_color)


func _on_focus_exited():
	$Name.add_color_override('font_color', default_color)
