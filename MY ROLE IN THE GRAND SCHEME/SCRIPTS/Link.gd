@tool
class_name Link extends Node2D

@export var card1: Card:
	set(value):
		if card1:
			card1.position_changed.disconnect(_update_transform)
		card1 = value
		if card1:
			card1.position_changed.connect(_update_transform)
		_update_transform()

@export var pin1: Card.PinLocation:
	set(value):
		pin1 = value
		_update_transform()

@export var card2: Card:
	set(value):
		if card2:
			card2.position_changed.disconnect(_update_transform)
		card2 = value
		if card2:
			card2.position_changed.connect(_update_transform)
		_update_transform()

@export var pin2: Card.PinLocation:
	set(value):
		pin2 = value
		_update_transform()

@export var texture: Texture2D:
	set(value):
		texture = value
		$Link_Texture.texture = value

@export var thickness: float = 3:
	set(value):
		thickness = value
		_update_transform()

func _update_transform():
	if not (card1 and card2):
		return

	var pos1 = card1.get_pin(pin1).global_position
	var pos2 = card2.get_pin(pin2).global_position
	pos1.y -= thickness * 0.5
	pos2.y -= thickness * 0.5
	$Link_Texture.global_position = pos1
	$Link_Texture.size = Vector2(pos1.distance_to(pos2), thickness)
	$Link_Texture.rotation = pos1.angle_to_point(pos2)
	
	# TODO: update collider shape

func _on_link_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.link_right_click.emit(event.global_position, self)
