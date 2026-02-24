@tool
class_name Pin extends Node2D

#
# There is a one-to-one correspondence between Pin.Location values and nodes in
# the Pin_Locators scene. If you change one, be sure to change the other!
#
enum Location {
	TOP_LEFT,
	TOP_LEFT_MORE,
	TOP_CENTER_LEFT,
	TOP_CENTER_LEFT_MORE,
	TOP_CENTER,
	TOP_CENTER_MORE,
	TOP_CENTER_RIGHT,
	TOP_CENTER_RIGHT_MORE,
	TOP_RIGHT,
	LEFT_CENTER,
	LEFT_CENTER_MORE,
	BOTTOM_LEFT,
	RIGHT_CENTER,
	BOTTOM_RIGHT,
	BOTTOM_CENTER_LEFT,
	BOTTOM_CENTER,
	BOTTOM_CENTER_RIGHT,
	LEFT_CENTER_LEFT,
	LEFT_CENTER_LEFT_MORE,
	CENTER,
	CENTER_MORE,
	RIGHT_CENTER_RIGHT,
	RIGHT_CENTER_RIGHT_MORE
}

## The pin can be attached to a card or to a link.
@export var backing: Node2D:
	set(value):
		if backing:
			if backing is Card:
				backing.remove_pin(card_location)
			elif backing is Link:
				backing.remove_follower_pin(self)
		backing = value
		if backing:
			if backing is Card:
				backing.add_pin(self, card_location)
			elif backing is Link:
				backing.add_follower_pin(self)

## Where on the card is the pin attached (if backing is a card)?
@export var card_location: Location:
	set(value):
		if card_location != value:
			if backing is Card:
				backing.move_pin(card_location, value)
			card_location = value

## Where on the link is the pin attached, between 0 and 1 (if backing is a link)?
@export_range(0.01, 0.99, 0.01) var link_location: float = 0.5:
	set(value):
		if link_location != value:
			link_location = value
			if backing is Link:
				link_location_changed.emit()

## Signal emitted when the pin's position may have changed.
signal moved

## Signal emitted when the pin's link_location has changed.
signal link_location_changed

static var _pin_scene = preload("res://SCENES/Pin_Small.tscn")

# The link for which this pin is one of the two endpoints.
var _link_ref: Link

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func _ready():
	set_notify_transform(true)

func _notification(what: int):
	if not Engine.is_editor_hint():
		match what:
			NOTIFICATION_PREDELETE:
				backing = null
			NOTIFICATION_TRANSFORM_CHANGED:
				moved.emit()

func pause_collisions():
	$Collider.input_pickable = false

func resume_collisions():
	$Collider.input_pickable = true

##
## Attaches the pin to a card at one of the card's predefined pin locations.
##
func move_to_card(to_card: Card, to_location: Location):
	backing = null
	card_location = to_location
	backing = to_card

##
## Attaches the pin to an existing link, somewhere between the link's first (0)
## and second (1) pin.
##
func move_to_link(to_link: Link, to_location: float = 0.5):
	backing = null
	link_location = clampf(to_location, 0.01, 0.99)
	backing = to_link

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

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.PIN

#
# For save/load.
#
func get_unique_id():
	return "pin%d" % _unique_id

#
# For save/load.
#
func get_referenced_objects():
	var refs = []
	if backing:
		refs.append(backing)
	if _link_ref:
		refs.append(_link_ref)
	return refs

#
# For save/load.
#
func get_json_dict():
	var dict = {}
	if backing is Card:
		dict["card_location"] = card_location
	elif backing is Link:
		dict["link_location"] = link_location
	if position.x != 0.0:
		dict["x"] = position.x
	if position.y != 0.0:
		dict["y"] = position.y
	if backing:
		dict["backing"] = backing.get_unique_id()
	if _link_ref:
		dict["link_ref"] = _link_ref.get_unique_id()
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	card_location = dict.get("card_location", Location.TOP_LEFT)
	link_location = dict.get("link_location", 0.5)
	position = Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
	if "backing" in dict:
		backing = catalog[dict.backing]
	# temporary (don't break old save files)
	elif "card" in dict:
		backing = catalog[dict.card]
	# temporary (don't break old save files)
	elif "link" in dict:
		backing = catalog[dict.link]
	if "link_ref" in dict:
		_link_ref = catalog[dict.link_ref]

#
# For save/load.
#
static func allocate() -> Object:
	return _pin_scene.instantiate()
