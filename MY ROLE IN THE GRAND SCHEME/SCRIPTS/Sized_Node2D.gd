@tool
class_name SizedNode2D extends Node2D

## A SizedNode2D is just a Node2D with an additional size property, and an
## option allowing you to display its bounding box in the Godot editor.

@export var size: Vector2:
	set = set_size, get = get_size

@export var show_bounding_box: bool = false:
	set(value):
		show_bounding_box = value
		queue_redraw()

func set_size(new_size: Vector2):
	if size != new_size:
		size = new_size
		queue_redraw()

func get_size() -> Vector2:
	return size

func _draw():
	if show_bounding_box and Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(0, 0), size), Color.GREEN, false, 1)
