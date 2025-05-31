@tool
class_name Link extends Node2D

@export var card1: Card:
	set(value):
		if card1 != value:
			_disconnect_pin1()
			card1 = value
			_connect_pin1()
			_update_transform()

@export var pin1: Card.PinLocation:
	set(value):
		if pin1 != value:
			_disconnect_pin1()
			pin1 = value
			_connect_pin1()
			_update_transform()

@export var card2: Card:
	set(value):
		if card2 != value:
			_disconnect_pin2()
			card2 = value
			_connect_pin2()
			_update_transform()

@export var pin2: Card.PinLocation:
	set(value):
		if pin2 != value:
			_disconnect_pin2()
			pin2 = value
			_connect_pin2()
			_update_transform()

@export var texture: Texture2D:
	set(value):
		texture = value
		$Link_Texture.texture = value

@onready var _thickness: float = $Link_Texture.size.y

func _ready():
	_update_transform()
	_show_or_hide()

##
## Returns true if both of the link's endpoints have been fully specified (card
## and pin location).
##
func has_both_endpoints():
	return (card1 and card2 and
			pin1 != Card.PinLocation.NONE and pin2 != Card.PinLocation.NONE)

func set_endpoint1(card: Card, pin: Card.PinLocation):
	if card1 != card or pin1 != pin:
		pin1 = Card.PinLocation.NONE
		card1 = card
		pin1 = pin

func set_endpoint2(card: Card, pin: Card.PinLocation):
	if card2 != card or pin2 != pin:
		pin2 = Card.PinLocation.NONE
		card2 = card
		pin2 = pin

func _connect_pin1():
	if card1:
		card1.stacked_changed.connect(_show_or_hide)
		if pin1 != Card.PinLocation.NONE:
			var pin = card1.get_pin(pin1)
			pin.moved.connect(_update_transform)
			pin.show()

func _disconnect_pin1():
	if card1:
		card1.stacked_changed.disconnect(_show_or_hide)
		if pin1 != Card.PinLocation.NONE:
			var pin = card1.get_pin(pin1)
			pin.moved.disconnect(_update_transform)
			pin.hide()

func _connect_pin2():
	if card2:
		card2.stacked_changed.connect(_show_or_hide)
		if pin2 != Card.PinLocation.NONE:
			var pin = card2.get_pin(pin2)
			pin.moved.connect(_update_transform)
			pin.show()

func _disconnect_pin2():
	if card2:
		card2.stacked_changed.disconnect(_show_or_hide)
		if pin2 != Card.PinLocation.NONE:
			var pin = card2.get_pin(pin2)
			pin.moved.disconnect(_update_transform)
			pin.hide()

func _update_transform():
	if not has_both_endpoints():
		return

	# update texture

	var pos1 = card1.get_pin(pin1).global_position
	var pos2 = card2.get_pin(pin2).global_position
	pos1.y -= _thickness * 0.5
	pos2.y -= _thickness * 0.5
	$Link_Texture.global_position = pos1
	$Link_Texture.size.x = pos1.distance_to(pos2)
	$Link_Texture.rotation = pos1.angle_to_point(pos2)
	
	# update collider shape

	var collider = $Link_Texture/Link_Collider/Collider
	var rectangle_shape = collider.shape
	if rectangle_shape is RectangleShape2D:
		rectangle_shape.size = $Link_Texture.size
		collider.position.x = $Link_Texture.size.x / 2

func _show_or_hide():
	visible = has_both_endpoints() and not (card1.is_stacked or card2.is_stacked)
	if card1:
		card1.get_pin(pin1).visible = visible
	if card2:
		card2.get_pin(pin2).visible = visible

func _on_link_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.link_right_click.emit(event.global_position, self)

##
## Returns true if the link is connected to the given pin at either end.
##
func is_connected_to_pin(pin: Pin_Small) -> bool:
	if card1 and not card1.is_stacked and pin1 != Card.PinLocation.NONE:
		if card1.get_pin(pin1) == pin:
			return true
	if card2 and not card2.is_stacked and pin2 != Card.PinLocation.NONE:
		if card2.get_pin(pin2) == pin:
			return true
	return false
