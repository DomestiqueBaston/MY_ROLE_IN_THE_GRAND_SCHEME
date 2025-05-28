@tool
class_name Link extends Node2D

@export var card1: Card:
	set(value):
		if card1:
			card1.position_changed.disconnect(_update_transform)
			card1.stacked_changed.disconnect(_show_or_hide)
		card1 = value
		if card1:
			card1.position_changed.connect(_update_transform)
			card1.stacked_changed.connect(_show_or_hide)
		_update_transform()

@export var pin1: Card.PinLocation:
	set(value):
		pin1 = value
		_update_transform()

@export var card2: Card:
	set(value):
		if card2:
			card2.position_changed.disconnect(_update_transform)
			card2.stacked_changed.disconnect(_show_or_hide)
		card2 = value
		if card2:
			card2.position_changed.connect(_update_transform)
			card2.stacked_changed.connect(_show_or_hide)
		_update_transform()

@export var pin2: Card.PinLocation:
	set(value):
		pin2 = value
		_update_transform()

@export var texture: Texture2D:
	set(value):
		texture = value
		$Link_Texture.texture = value

@onready var _thickness: float = $Link_Texture.size.y

func _ready():
	_show_or_hide()

func _update_transform():
	if not (card1 and card2):
		return

	# update texture

	var pos1 = card1.get_pin(pin1).global_position
	var pos2 = card2.get_pin(pin2).global_position
	pos1.y -= _thickness * 0.5
	pos2.y -= _thickness * 0.5
	$Link_Texture.global_position = pos1
	$Link_Texture.size = Vector2(pos1.distance_to(pos2), _thickness)
	$Link_Texture.rotation = pos1.angle_to_point(pos2)
	
	# update collider shape

	var collider = $Link_Texture/Link_Collider/Collider
	var rectangle_shape = collider.shape
	if rectangle_shape is RectangleShape2D:
		rectangle_shape.size = $Link_Texture.size
		collider.position.x = $Link_Texture.size.x / 2

func _show_or_hide():
	visible = card1 and card2 and not (card1.is_stacked or card2.is_stacked)
	if card1:
		card1.get_pin(pin1).visible = visible
	if card2:
		card2.get_pin(pin2).visible = visible

func _on_link_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.link_right_click.emit(event.global_position, self)
