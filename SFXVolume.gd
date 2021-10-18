extends Control

var selected = false


func _ready():
	$HSlider.value = round(SoundManager.get_se_volume_db())


func _process(delta):
	if not selected:
		return
	if Input.is_action_just_pressed('ui_left'):
		$HSlider.set_value($HSlider.value - 5)
	if Input.is_action_just_pressed('ui_right'):
		$HSlider.set_value($HSlider.value + 5)

	SoundManager.set_se_volume_db($HSlider.value if $HSlider.value > $HSlider.min_value else -81)
