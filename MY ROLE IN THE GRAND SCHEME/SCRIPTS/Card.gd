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

enum CombatType {
	NONE,
	SPECIAL,
	RUN_AWAY
}

enum InvestigationType {
	NONE,
	SPECIAL,
	BREAK_IN
}

enum LocationStatus {
	NONE,
	CLOSED,
	CRIME_SCENE
}

enum NpcHealth {
	NONE,
	GOOD,
	AVERAGE,
	LOW
}

enum NpcStatus {
	NONE,
	JAIL,
	DEAD,
	DISAPPEARED,
	MINION
}

@export var card_name: String = "Card Name":
	set(value):
		card_name = value
		if $Card_Mask/Card_BG/Card_Text/Card_Name:
			$Card_Mask/Card_BG/Card_Text/Card_Name.text = card_name

@export var description: String = "Short card description.":
	set(value):
		description = value
		if $Card_Mask/Card_BG/Card_Text/Card_Name:
			$Card_Mask/Card_BG/Card_Text/Card_Description.text = description

@export var card_type: CardType:
	set(value):
		card_type = value
		_update_card_type()

@export var combat_type: CombatType:
	set(value):
		combat_type = value
		_update_card_type()

@export var investigation_type: InvestigationType:
	set(value):
		investigation_type = value
		_update_card_type()

@export var location_status: LocationStatus:
	set(value):
		location_status = value
		_update_card_type()

@export var npc_health: NpcHealth:
	set(value):
		npc_health = value
		_update_card_type()

@export var npc_status: NpcStatus:
	set(value):
		npc_status = value
		_update_card_type()

@export var is_object_evidence: bool:
	set(value):
		is_object_evidence = value
		_update_card_type()

@export var opacity: float = 1:
	set(value):
		opacity = value
		_update_opacity()

## Size of a card in pixels.
const size := Vector2i(74, 100)

var _is_highlighted: bool = false
var _opacity_before_highlighting: float
var _is_expanded: bool = true
var _pins = {}

func _ready():
	set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		for location in _pins:
			_pins[location].global_position = get_pin_position(location)

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
	if is_stacked():
		# because a stacked card's Z index is incremented when highlighted
		if _is_highlighted:
			z_index -= 1
		for location in _pins:
			_pins[location].show()

func _update_card_type():
	match card_type:
		CardType.COMBAT:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = true
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Card_Color/Combat/Special.visible = (combat_type == CombatType.SPECIAL)
			$Card_Mask/Card_BG/Card_Color/Combat/Run_Away.visible = (combat_type == CombatType.RUN_AWAY)
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.INVESTIGATION:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = true
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation/Special.visible = (investigation_type == InvestigationType.SPECIAL)
			$Card_Mask/Card_BG/Card_Color/Investigation/Break_In.visible = (investigation_type == InvestigationType.BREAK_IN)
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.DIALOGUE:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = true
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.ABSTRACT:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = true
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.OBJECT:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = true
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = is_object_evidence
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.LOCATION:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = true
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = (location_status == LocationStatus.CLOSED)
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = (location_status == LocationStatus.CRIME_SCENE)
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.NPC:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = true
			$Card_Mask/Card_BG/Card_Color/Npc/No_Info.visible = (npc_health == NpcHealth.NONE)
			$Card_Mask/Card_BG/Card_Color/Npc/Good_Health.visible = (npc_health == NpcHealth.GOOD)
			$Card_Mask/Card_BG/Card_Color/Npc/Average_Health.visible = (npc_health == NpcHealth.AVERAGE)
			$Card_Mask/Card_BG/Card_Color/Npc/Low_Health.visible = (npc_health == NpcHealth.LOW)
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = (npc_status == NpcStatus.JAIL)
			$Card_Mask/Card_BG/Dead_Status.visible = (npc_status == NpcStatus.DEAD)
			$Card_Mask/Card_BG/Disappeared_Status.visible = (npc_status == NpcStatus.DISAPPEARED)
			$Card_Mask/Card_BG/Minion_Status.visible = (npc_status == NpcStatus.MINION)

#func get_size() -> Vector2i:
	#return Vector2i(
		#$Card_Mask.texture.get_width() / $Card_Mask.hframes,
		#$Card_Mask.texture.get_height() / $Card_Mask.vframes)

func get_pin_position(which: int) -> Vector2:
	return $Pin_Locators.get_child(which).global_position

##
## Expands (true) or reduces (false) the card.
##
func set_expanded(expanded: bool):
	if _is_expanded != expanded:
		if expanded:
			$Card_Animations.play("Expand_Card")
		else:
			$Card_Animations.play("Reduce_Card")
		_is_expanded = expanded

##
## Expands the card if it is reduced, reduces it if it is expanded.
##
func expand_or_reduce():
	set_expanded(not _is_expanded)

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
				if other_pin.type == Pin.PinType.CARD:
					other_pin.card._raise(false)

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
				p.link.move_to_front()
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

func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if $Card_Animations.is_playing():
			pass
		elif event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			Globals.card_right_click.emit(event.global_position, self)
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
## Modifies the appearance of the card to show it is being dragged.
##
func start_drag():
	if _is_expanded:
		$Card_Animations.play("Drag_Expanded_Card_Appearance")
	else:
		$Card_Animations.play("Drag_Reduced_Card_Appearance")
	$Shadow_Animations.play("Shadow_Off")
	z_index += 1

##
## Resets the appearance of the card after a call to start_drag().
##
func stop_drag():
	if _is_expanded:
		$Card_Animations.play("Drag_Expanded_Card_Disappearance")
	else:
		$Card_Animations.play("Drag_Reduced_Card_Disappearance")
	$Shadow_Animations.play("Shadow_On")
	z_index -= 1

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
