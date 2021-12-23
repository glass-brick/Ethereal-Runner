tool
extends Control

export (bool) var autoscroll_active := false
export (float) var scroll_speed := 0.1 
export (int) var hold_time := 200

var scroll_containers = []

# var time_between_scrolls : int = 10 - scroll_speed if scroll_speed < 10 else 0
# var scroll_timer := time_between_scrolls

var progress = 0.0
var direction := 1
var scroll_hold_timer := hold_time


func _ready():
	scroll_containers = find_all_scrollable_children()


func get_max_scroll(scroll_container: ScrollContainer):
	var sum = Vector2(0, 0)
	for child in scroll_container.get_children():
		if child is HScrollBar:
			sum.y += child.rect_size.y
		elif child is VScrollBar:
			sum.x += child.rect_size.x
		else:
			sum += child.rect_size
	var result = Vector2(max(0, sum.x - scroll_container.rect_size.x), max(0, sum.y - scroll_container.rect_size.y))
	return result

func _process(delta):
	for container in scroll_containers:
		container.scroll_horizontal = int(progress * get_max_scroll(container).x)
		container.scroll_vertical = int(progress * get_max_scroll(container).y)
	if autoscroll_active:
		progress = clamp(progress + delta * scroll_speed * direction, 0.0, 1.0)
		if progress == 0.0 or progress == 1.0:
			if scroll_hold_timer > 0:
				prints(scroll_hold_timer)
				scroll_hold_timer -= 1
			else:
				scroll_hold_timer = hold_time
				direction *= -1

func reset_scroll():
	progress = 0.0
	direction = 1


func find_all_scrollable_children():
	var _scroll_containers = []
	var queue := [self]
	while queue.size() > 0:
		var container = queue.pop_front()
		if container is ScrollContainer:
			_scroll_containers.append(container)
		for child in container.get_children():
			queue.append(child)
	return _scroll_containers
