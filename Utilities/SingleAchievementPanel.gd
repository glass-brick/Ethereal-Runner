extends PanelContainer

export (Color) var focus_color = Color(0x1b692b)
onready var default_theme = get('custom_styles/panel')
onready var focus_theme = get('custom_styles/panel').duplicate()


func _ready():
	focus_theme.bg_color = focus_color


func set_achievement(achievement):
	$HBoxContainer/Image.texture = (
		load(achievement["icon_path"])
		if achievement["achieved"]
		else null
	)
	$HBoxContainer/VBoxContainer/Title.text = (
		achievement["name"]
		if achievement["achieved"]
		else "?????"
	)
	$HBoxContainer/VBoxContainer/Description.text = achievement["description"]


func _on_focus_exited():
	set('custom_styles/panel', default_theme)


func _on_focus_entered():
	set('custom_styles/panel', focus_theme)
