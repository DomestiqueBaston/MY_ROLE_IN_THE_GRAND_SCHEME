@tool
class_name Card extends Node2D

enum CardType {
	COMBAT,
	INVESTIGATION,
	DIALOGUE,
	ABSTRACT,
	OBJECT,
	LOCATION,
	NPC
}

enum RevealStatus {
	HIDDEN,
	LIMBO,
	REVEALED
}

@export var card_name: String:
	set(value):
		card_name = value
		if is_node_ready():
			$Card_Mask/Card_BG/Card_Text/Card_Name.text = get_display_name()

@export var description: String:
	set(value):
		description = value
		if is_node_ready():
			$Card_Mask/Card_BG/Card_Text/Card_Description.text = description

@export var tooltip: String

@export var opacity: float = 1:
	set(value):
		opacity = value
		if is_node_ready():
			_update_opacity()

## Has the card been revealed to the player?
var reveal_status: RevealStatus = RevealStatus.HIDDEN

## Was the card in the main scene's reserve pile before it was removed from the
## scene?
var was_stacked: bool = false

## Size of a card in pixels.
const size := Vector2i(74, 100)

## Size of a card when it has been reduced.
const reduced_size := Vector2i(74, 27)

## Signal emitted when the card's position has changed.
signal moved

# Maps link types to arrays of cards (locations, objects and NPCs).
var _connections: Dictionary

#
# Class which allows us to save the state of a card (its position, whether it is
# expanded or reduced, etc.) and restore it later. This is done when the game
# switches from the main scene to the interaction scene and back again. Some
# cards (object, location and NPC cards) are visible in both scenes, and can be
# manipulated in both scenes. So card states are saved before the interaction
# scene is brought up, and restored afterward. And saved states are saved with
# the game, in case the user quits in the middle of an interaction.
#
class State:
	var is_stacked: bool
	var is_expanded: bool
	var position: Vector2

	func _init(card: Card = null):
		if card:
			is_stacked = card.is_stacked()
			is_expanded = card.is_expanded()
			position = card.position
		else:
			is_stacked = false
			is_expanded = true

	func restore(card: Card):
		card.was_stacked = is_stacked
		card.set_expanded(is_expanded, false)
		card.position = position

var _state_stack: Array[State]
var _is_highlighted: bool = false
var _opacity_before_highlighting: float
var _is_expanded: bool = true
var _pins = {}

func _ready():
	$Card_Mask/Card_BG/Card_Text/Card_Name.text = get_display_name()
	$Card_Mask/Card_BG/Card_Text/Card_Description.text = description
	_update_opacity()

	if not _is_expanded:
		$Card_Animations.play("Static_Reduced")

	if not Engine.is_editor_hint():
		$Card_Collider.input_event.connect(_on_card_collider_input_event)
		$Card_Collider.mouse_entered.connect(_on_card_collider_mouse_entered)
		$Card_Collider.mouse_exited.connect(_on_card_collider_mouse_exited)
		set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		for location in _pins:
			_pins[location].global_position = get_pin_position(location)
		moved.emit()

##
## Returns the type of the card (to be overridden by each subclass).
##
func get_card_type() -> CardType:
	return 0 as CardType

##
## Returns true if the card is in a stack, that is, if its parent node is a
## CardStack. Note that when a card is in a stack, its parent node decides which
## card to highlight, not the card itself. That is, a stacked card emits no
## Globals.mouse_entered_card() and Globals.mouse_exited_card() signals; its
## CardStack parent emits them.
##
func is_stacked() -> bool:
	var parent = get_parent()
	return parent and parent is CardStack

##
## When the card is parented to a CardStack, hide its pins.
##
func _enter_tree():
	if is_stacked():
		# because a stacked card's Z index is incremented when highlighted
		if _is_highlighted:
			z_index += 1
		for location in _pins:
			_pins[location].hide()

##
## When the card is removed from its CardStack parent, show its pins.
##
func _exit_tree():
	was_stacked = is_stacked()
	if was_stacked:
		# because a stacked card's Z index is incremented when highlighted
		if _is_highlighted:
			z_index -= 1
		for location in _pins:
			_pins[location].show()

func get_pin_position(which: int) -> Vector2:
	return $Pin_Locators.get_child(which).global_position

func is_expanded() -> bool:
	return _is_expanded

##
## Expands (true) or reduces (false) the card. If with_animation is false, the
## transition is instantaneous.
##
func set_expanded(expanded: bool, with_animation: bool = true):
	if _is_expanded != expanded:
		if expanded:
			if with_animation:
				$Card_Animations.play("Expand_Card")
			else:
				$Card_Animations.play("Static_Expanded")
		else:
			if with_animation:
				$Card_Animations.play("Reduce_Card")
			else:
				$Card_Animations.play("Static_Reduced")
		_is_expanded = expanded

##
## Expands the card if it is reduced, reduces it if it is expanded.
##
func expand_or_reduce():
	set_expanded(not _is_expanded)

##
## Causes the card to blink briefly.
##
func blink():
	$Card_Animations.play("Card_Blink")

##
## Specifies whether or not the card is highlighted. When a card is highlighted,
## its Z index is increased and its shadow is displayed. Sounds are played when
## a card's highlight state changes.
##
func set_highlighted(highlighted: bool):
	if _is_highlighted == highlighted:
		return

	if highlighted:
		if is_stacked():
			$Card_Shadow.position = Vector2(0, 0)
			$Card_Shadow.show()
			z_index += 1
		else:
			$Shadow_Animations.play("Shadow_On")
			_raise()
		_opacity_before_highlighting = opacity
		if opacity < 1:
			create_tween().tween_property(self, "opacity", 1, 0.1333)
		if Globals.card_exited_sound.playing:
			Globals.card_exited_sound.stop()
		if not Globals.card_entered_sound.playing:
			Globals.card_entered_sound.play()
	else:
		if is_stacked():
			$Card_Shadow.hide()
			$Card_Shadow.position = Vector2(-2, -4)
			z_index -= 1
		else:
			$Shadow_Animations.play("Shadow_Off")
		if _opacity_before_highlighting < 1:
			create_tween().tween_property(
				self, "opacity", _opacity_before_highlighting, 0.1333)
		if not Globals.card_entered_sound.playing:
			Globals.card_exited_sound.play()

	_is_highlighted = highlighted

##
## If locked is true, an animation is played to indicate that this card has
## been locked, that is, information about it is displayed in the info box until
## further notice. Call with false when the card is unlocked.
##
func set_locked(locked: bool):
	$Activation_Card_Animations.play("Active_Card" if locked else "RESET")

#
# Moves the card in front of its siblings, then does the same for any links to
# the card, and finally for the pins on those links. This should not be done for
# a stacked card, which is raised by modifying its Z index and does not display
# any pins or links. For other cards, though, cards, pins and links are all
# parented to the same node, and this ensures that, for the highlighted card, at
# least, links are displayed above the card and pins are displayed above the
# links.
#
# If raise_neighbors is true, any cards connected to this one are raised first.
#
func _raise(raise_neighbors: bool = false):

	# first, recursively raise any other cards that are connected to this one
	# (along with their pins and links)

	if raise_neighbors:
		for location in _pins:
			var pin = _pins[location]
			var link = pin.get_link_reference()
			if link:
				var other_pin
				if link.pin1 == pin:
					other_pin = link.pin2
				else:
					other_pin = link.pin1
				if other_pin.backing is Card:
					other_pin.backing._raise(false)

	# now move the card itself in front

	move_to_front()

	# finally, raise any links connected to this card, and the pins connected to
	# those links

	for location in _pins:
		var pin = _pins[location]
		var link = pin.get_link_reference()
		if link:
			link.move_to_front()
			for p in link.get_follower_pins():
				p.backing.move_to_front()
			link.pin1.move_to_front()
			link.pin2.move_to_front()
			for p in link.get_follower_pins():
				p.move_to_front()
		else:
			pin.move_to_front()

func _update_opacity():
	$Card_Mask.modulate.a = opacity
	if $Card_Shadow.material:
		$Card_Shadow.material.set_shader_parameter(
			"shadow_color", Color(0, 0, 0, opacity * 0.3))

#
# Note that for left click events, we DO NOT set the input as handled. When cards are drawn in the
# break-in overlay on top of the main scene, two overlapping cards may both receive input events,
# even though Viewport.physics_object_picking_sort and Viewport.physics_object_picking_first_only
# are set to true. What's more, the cards in the main scene seem to receive the events before the
# cards in the overlay on top of them. I have no idea why. To work around the problem, we leave the
# input event unhandled, meaning two clicks are received, and the overlay ignores clicks from cards
# that do not belong to it. See issue #115.
#
func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		if $Card_Animations.is_playing():
			pass
		elif event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			Globals.card_right_click.emit(event.global_position, self)
			get_viewport().set_input_as_handled()
		elif event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if event.double_click:
				Globals.card_double_click.emit(self)
			else:
				Globals.card_left_click.emit(event.global_position, self)

func _on_card_collider_mouse_entered():
	if not is_stacked():
		Globals.mouse_entered_card.emit(self)

func _on_card_collider_mouse_exited():
	if not is_stacked():
		Globals.mouse_exited_card.emit(self)

##
## Modifies the appearance of the card to show it is being dragged. This is a
## coroutine: await it if you want to wait until the animation finishes.
##
func start_drag():
	if _is_expanded:
		$Card_Animations.play("Drag_Expanded_Card_Appearance")
	else:
		$Card_Animations.play("Drag_Reduced_Card_Appearance")
	$Shadow_Animations.play("Shadow_Off")
	z_index += 1
	await $Shadow_Animations.animation_finished

##
## Resets the appearance of the card after a call to start_drag(). This is a
## coroutine: await it if you want to wait until the animation finishes.
##
func stop_drag():
	if _is_expanded:
		$Card_Animations.play("Drag_Expanded_Card_Disappearance")
	else:
		$Card_Animations.play("Drag_Reduced_Card_Disappearance")
	$Shadow_Animations.play("Shadow_On")
	z_index -= 1
	await $Shadow_Animations.animation_finished

##
## Adds a pin reference to the card: whenever the card moves, the pin's
## position will be updated automatically.
##
func add_pin(pin: Pin, location: Pin.Location):
	_pins[location] = pin
	pin.global_position = get_pin_position(location)

##
## Removes a pin reference after a call to add_pin().
##
func remove_pin(location: Pin.Location):
	_pins.erase(location)

##
## Moves a pin that was previously added by add_pin() to a different location
## on the card.
##
func move_pin(from: Pin.Location, to: Pin.Location):
	var pin = _pins[from]
	_pins.erase(from)
	_pins[to] = pin
	pin.global_position = get_pin_position(to)

##
## Returns an array containing the pins that have been added to this card: see
## add_pin().
##
func get_pins() -> Array[Pin]:
	var pins: Array[Pin]
	for location in _pins:
		pins.append(_pins[location])
	return pins

##
## Given a position in global coordinates, returns the closest location on the
## card (a Pin.Location enum) where no pin has yet been registered: see
## add_pin(). Returns -1 if all the card's pin locations are already in use.
##
func find_closest_unused_pin(global_pos: Vector2) -> int:
	var min_dist2 = -1
	var min_pin = -1

	for i in $Pin_Locators.get_child_count():
		if i not in _pins:
			var locator = $Pin_Locators.get_child(i)
			var dist2 = global_pos.distance_squared_to(locator.global_position)
			if min_dist2 < 0 or min_dist2 > dist2:
				min_dist2 = dist2
				min_pin = i

	return min_pin

##
## Returns a list of cards that have links to this card. If link_type is given,
## only links of that type are taken into consideration.
##
func find_linked_cards(link_type: int = -1) -> Array[Card]:
	var ret: Array[Card]
	for pin in _pins.values():
		var link = pin.get_link_reference()
		if link and (link_type < 0 or link_type == link.type):
			if pin == link.pin1:
				if link.pin2.backing is Card:
					ret.append(link.pin2.backing)
			elif pin == link.pin2:
				if link.pin1.backing is Card:
					ret.append(link.pin1.backing)
	return ret

##
## Returns a list of links to this card. If link_type is given, only links of
## that type are taken into consideration. Temporary links are ignored.
##
func find_links(link_type: int = -1) -> Array[Link]:
	var ret: Array[Link]
	for pin in _pins.values():
		var link = pin.get_link_reference()
		if (link and (link_type < 0 or link_type == link.type)
			and not link.is_temporary()):
			ret.append(link)
	return ret

func _add_connection(type: Link.Type, card: Card):
	if type in _connections:
		_connections[type].append(card)
	else:
		_connections[type] = [card]

##
## Static function to add a bidirectional connection between two cards.
##
static func add_bidirectional_connection(type: Link.Type, card_a: Card, card_b: Card):
	card_a._add_connection(type, card_b)
	card_b._add_connection(type, card_a)

func get_all_connections() -> Array[Card]:
	var cnxs: Array[Card]
	for cnx_array in _connections.values():
		cnxs.append_array(cnx_array)
	return cnxs

func get_all_npc_connections() -> Array[NpcCard]:
	var cnxs: Array[NpcCard]
	for cnx_array in _connections.values():
		for cnx in cnx_array:
			if cnx is NpcCard:
				cnxs.append(cnx)
	return cnxs

func get_all_location_connections() -> Array[LocationCard]:
	var cnxs: Array[LocationCard]
	for cnx_array in _connections.values():
		for cnx in cnx_array:
			if cnx is LocationCard:
				cnxs.append(cnx)
	return cnxs

func get_all_object_connections() -> Array[ObjectCard]:
	var cnxs: Array[ObjectCard]
	for cnx_array in _connections.values():
		for cnx in cnx_array:
			if cnx is ObjectCard:
				cnxs.append(cnx)
	return cnxs

func get_connections(type: Link.Type) -> Array[Card]:
	var cnxs: Array[Card]
	if type in _connections:
		cnxs.assign(_connections[type])
	return cnxs

func get_one_connection(type: Link.Type) -> Card:
	if type in _connections:
		return _connections[type][0]
	return null

func has_connection(type: Link.Type) -> bool:
	return type in _connections

##
## Looks for the first connection between this card and another. Returns the
## type of connection found (a Link.Type), or -1 if none was found.
##
func get_connection_to(other: Card) -> int:
	for type in _connections:
		if other in _connections[type]:
			return type
	return -1

func print_connections_of_type(label: String, type: Link.Type):
	var cnxs = get_connections(type)
	if cnxs:
		var text = ""
		for cnx in cnxs:
			if not text.is_empty():
				text += ", "
			text += cnx.get_display_name()
		print("  ", label, ": ", text)
	else:
		print("  ", label, ": none")

##
## Pushes the current state of the card (position, expanded/reduced, in a stack
## or not) onto a stack, so that it can be modified and restored later. The
## state stack is saved and restored along with the game.
##
func push_state():
	_state_stack.push_back(State.new(self))

##
## Restores the state of the card from the last time push_state() was called,
## popping the saved state off the stack. Returns false if push_state() has not
## been called.
##
func pop_state() -> bool:
	if _state_stack.is_empty():
		push_error("pop_state: stack is empty for card ", get_display_name())
		return false
	else:
		_state_stack.pop_back().restore(self)
		return true

##
## Returns the card's name to display in the UI. By default, this is just the
## card_name property, but some subclasses (NpcCard, LocationCard) override this
## method and may not use card_name (or not always).
##
func get_display_name() -> String:
	return card_name

##
## Card subclasses should call this when the display name has changed, to update
## the UI.
##
func display_name_changed():
	if is_node_ready():
		$Card_Mask/Card_BG/Card_Text/Card_Name.text = get_display_name()

##
## Returns detailed information about the card to be displayed in the UI. This
## is not handled by all card types.
##
func get_info() -> String:
	return ""

#
# For save/load.
#
func get_referenced_objects():
	return _pins.values() + get_all_connections()

#
# For save/load.
#
func get_json_dict():
	var dict = {}
	var stacked = is_stacked() if is_inside_tree() else was_stacked
	if stacked:
		dict["was_stacked"] = stacked
	if opacity != 1.0:
		dict["opacity"] = opacity
	if position.x != 0.0:
		dict["x"] = position.x
	if position.y != 0.0:
		dict["y"] = position.y
	if reveal_status != RevealStatus.HIDDEN:
		dict["reveal_status"] = reveal_status
	if not _is_expanded:
		dict["is_expanded"] = _is_expanded
	if _pins:
		var pin_refs = {}
		for pin in _pins:
			pin_refs[pin] = _pins[pin].get_unique_id()
		dict["pins"] = pin_refs
	if _connections:
		var cnx_dict = {}
		for type in _connections:
			var cnx_array = []
			for cnx in _connections[type]:
				cnx_array.append(cnx.get_unique_id())
			cnx_dict[type] = cnx_array
		dict["connections"] = cnx_dict
	if not _state_stack.is_empty():
		var state_array = []
		for state in _state_stack:
			state_array.append({
				"is_stacked": state.is_stacked,
				"is_expanded": state.is_expanded,
				"x": state.position.x,
				"y": state.position.y
			})
		dict["state_stack"] = state_array
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	opacity = dict.get("opacity", 1.0)
	was_stacked = dict.get("was_stacked", false)
	position = Vector2(dict.get("x", 0.0), dict.get("y", 0.0))
	reveal_status = dict.get("reveal_status", RevealStatus.HIDDEN)
	_is_expanded = dict.get("is_expanded", true)
	if "pins" in dict:
		var pin_refs = dict.pins
		for pin in pin_refs:
			_pins[pin as Pin.Location] = catalog[pin_refs[pin]]
	if "connections" in dict:
		for type in dict.connections:
			var refs = []
			for id in dict.connections[type]:
				refs.append(catalog[id])
			_connections[type as Link.Type] = refs
	if "state_stack" in dict:
		for entry in dict.state_stack:
			var state = State.new()
			state.is_stacked = entry.get("is_stacked", false)
			state.is_expanded = entry.get("is_expanded", true)
			state.position = Vector2(
				entry.get("x", 0.0),
				entry.get("y", 0.0))
			_state_stack.push_back(state)
