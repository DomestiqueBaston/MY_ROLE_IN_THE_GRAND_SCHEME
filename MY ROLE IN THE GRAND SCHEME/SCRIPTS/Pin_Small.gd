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
@export var card: Card:
	set(value):
		if type != PinType.CARD or card == value:
			return
		if card:
			card.remove_pin(location)
		card = value
		if card:
			card.add_pin(self, location)

## Where on the card is the pin attached (if type is CARD)?
@export var location: Location:
	set(value):
		if type == PinType.CARD and location != value:
			if card:
				card.move_pin(location, value)
			location = value

## Which link is the pin attached to (if type is LINK)?
@export var link: Link:
	set(value):
		if type == PinType.LINK and link != value:
			if link:
				link.remove_follower_pin(self)
			link = value
			if link:
				link.add_follower_pin(self)

## Signal emitted when the pin's position may have changed.
signal moved

func _ready():
	set_notify_transform(true)

func _exit_tree():
	if not Engine.is_editor_hint():
		card = null
		link = null

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		moved.emit()

func pause_collisions():
	$Collider.input_pickable = false

func resume_collisions():
	$Collider.input_pickable = true

func move_to_card(to_card: Card, to_location: Location):
	type = PinType.CARD
	card = null
	location = to_location
	card = to_card

func move_to_link(to_link: Link):
	type = PinType.LINK
	link = to_link

func _on_collider_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT and not event.double_click:
			Globals.pin_left_click.emit(event.global_position, self)
