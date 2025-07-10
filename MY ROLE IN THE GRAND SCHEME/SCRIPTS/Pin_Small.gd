@tool
class_name Pin extends Node2D

enum PinType {
	CARD,
	LINK
}

enum Location {
	TOP_LEFT,
	TOP_CENTER_LEFT,
	TOP_CENTER,
	TOP_CENTER_RIGHT,
	TOP_RIGHT,
	LEFT_CENTER,
	LEFT_BOTTOM,
	RIGHT_CENTER,
	RIGHT_BOTTOM
}

## Is the pin attached to a card or to a link?
@export var type: PinType = PinType.CARD:
	set(value):
		if type != value:
			if type == PinType.CARD:
				card = null
			else:
				link = null
			type = value

## Which card is the pin attached to (if type is CARD).
@export var card: BaseCard:
	set(value):
		if type != PinType.CARD or card == value:
			return
		if card:
			card.remove_pin(card_location)
		card = value
		if card:
			card.add_pin(self, card_location)

## Where on the card is the pin attached (if type is CARD)?
@export var card_location: Location:
	set(value):
		if card_location != value:
			if type == PinType.CARD and card:
				card.move_pin(card_location, value)
			card_location = value

## Which link is the pin attached to (if type is LINK)?
@export var link: Link:
	set(value):
		if type == PinType.LINK and link != value:
			if link:
				link.remove_follower_pin(self)
			link = value
			if link:
				link.add_follower_pin(self)

## Where on the link is the pin attached, between 0 and 1 (if type is LINK)?
@export_range(0.01, 0.99, 0.01) var link_location: float = 0.5:
	set(value):
		if link_location != value:
			link_location = value
			if type == PinType.LINK and link:
				link_location_changed.emit()

## Signal emitted when the pin's position may have changed.
signal moved

## Signal emitted when the pin's link_location has changed.
signal link_location_changed

static var _pin_scene = preload("res://SCENES/Pin_Small.tscn")

# The link for which this pin is one of the two endpoints.
var _link_ref: Link

func _ready():
	set_notify_transform(true)

func _notification(what: int):
	if not Engine.is_editor_hint():
		if what == NOTIFICATION_TRANSFORM_CHANGED:
			moved.emit()

func pause_collisions():
	$Collider.input_pickable = false

func resume_collisions():
	$Collider.input_pickable = true

##
## Attaches the pin to a card at one of the card's predefined pin locations.
##
func move_to_card(to_card: BaseCard, to_location: Location):
	type = PinType.CARD
	card = null
	card_location = to_location
	card = to_card

##
## Attaches the pin to an existing link, somewhere between the link's first (0)
## and second (1) pin.
##
func move_to_link(to_link: Link, to_location: float = 0.5):
	type = PinType.LINK
	link = null
	link_location = clampf(to_location, 0.01, 0.99)
	link = to_link

##
## Specifies for which link this pin is one of the two endpoints.
##
func set_link_reference(link_ref: Link):
	_link_ref = link_ref

##
## Returns the link for which this pin is one of the two endpoints.
##
func get_link_reference() -> Link:
	return _link_ref

##
## Attaches the pin to an existing link, positioning it initially at the point
## on the link nearest to the given position.
##
func move_to_link_at(to_link: Link, pos: Vector2):
	var vec = to_link.pin2.global_position - to_link.pin1.global_position
	var dist = to_link.pin1.global_position.distance_to(pos)
	move_to_link(to_link, dist / vec.length())

func _on_collider_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT and not event.double_click:
			Globals.pin_left_click.emit(event.global_position, self)

func get_custom_class():
	return SaveLoadTools.Class.PIN

func get_referenced_objects():
	var refs = []
	if card:
		refs.append(card)
	if link:
		refs.append(link)
	if _link_ref:
		refs.append(_link_ref)
	return refs

func get_json_dict():
	var dict = {}
	if type == PinType.CARD:
		dict["card_location"] = card_location
	else:
		dict["type"] = type
		dict["link_location"] = link_location
	if position.x != 0.0:
		dict["x"] = position.x
	if position.y != 0.0:
		dict["y"] = position.y
	if card:
		dict["card"] = SaveLoadTools.get_object_id(card)
	if link:
		dict["link"] = SaveLoadTools.get_object_id(link)
	if _link_ref:
		dict["link_ref"] = SaveLoadTools.get_object_id(_link_ref)
	return dict

func restore(dict, catalog):
	type = dict.get("type", PinType.CARD)
	card_location = dict.get("card_location", Location.TOP_LEFT)
	link_location = dict.get("link_location", 0.5)
	position = Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
	if "card" in dict:
		card = catalog[dict.card]
	if "link" in dict:
		link = catalog[dict.link]
	if "link_ref" in dict:
		_link_ref = catalog[dict.link_ref]

static func allocate() -> Object:
	return _pin_scene.instantiate()
