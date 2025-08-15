extends Node2D

@onready var cards: Node2D = $Cards
@onready var reserve: Node2D = $Reserve_Cards
@onready var drag_drop_line: Node2D = $Drag_Drop_Line
@onready var popup: PopupMenu = $Mask_Card_Playground/Popup_Menu
@onready var top_bar: Control = $Mask_Card_Playground/Top_Bar
@onready var info_box: Node2D = $Mask_Card_Playground/Bottom_Left_Info
@onready var location_bar = $Mask_Card_Playground/Player_Location/Text/Location
@onready var pin_scene: PackedScene = preload("res://SCENES/Pin_Small.tscn")
@onready var link_scene: PackedScene = preload("res://SCENES/Link.tscn")

## Signal emitted when the player selects Settings in the menu.
signal settings

## Signal emitted when the player selects Quit in the menu.
signal quit

enum MenuItem {
	DIALOGUE,
	INVESTIGATION,
	CREATE_CONF_LINK,
	CREATE_PROB_LINK,
	CHANGE_LINK_COLOR,
	SWITCH_LINK,
	DELETE_LINK,
	REMOVE_WARNING
}

# highlighted card
var _current_card: Card

# card whose info is displayed in the info box until further notice
var _blocked_info_card: Card

# the visible pin which has been clicked and not yet released
var _clicked_pin: Pin

# the card or link the mouse is over, while a pin is being dragged
var _drop_target: Node2D

# has something been clicked on, or is something being dragged?
enum DragState {
	NONE,		# nothing is going on
	CLICKED,		# a card or a pin has been clicked but is not being dragged yet
	DRAGGING,	# a card or a pin is being dragged
	LINKING		# the free end of a new link is being dragged
}
var _drag_state: DragState = DragState.NONE

# card or pin position in local coordinates when dragging began
var _drag_local_init_pos: Vector2

# card or pin position in global coordinates when dragging began
var _drag_global_init_pos: Vector2

# where the user clicked, in global coordinates, to initiate dragging
var _drag_click_pos: Vector2

# links connected to the card or pin being dragged
var _drag_links: Array[Link]

# card or link whose popup menu is displayed
var _popup_node: Node2D

# for creating a new link: source and destination pins and the link itself
var _src_pin: Pin
var _dst_pin: Pin
var _new_link: Link

# if true, all input handling is paused
var _input_paused: bool = false

func _ready():
	var submenu1 = popup.get_child(0)
	var submenu2 = submenu1.duplicate()
	var submenu3 = submenu1.duplicate()
	popup.add_child(submenu2)
	popup.add_child(submenu3)
	
	popup.add_item("Dialogue", MenuItem.DIALOGUE)
	popup.add_item("Investigation", MenuItem.INVESTIGATION)
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_submenu_node_item(
		"Create conf. link", submenu1, MenuItem.CREATE_CONF_LINK)
	popup.add_submenu_node_item(
		"Create prob. link", submenu2, MenuItem.CREATE_PROB_LINK)
	popup.add_submenu_node_item(
		"Change link color", submenu3, MenuItem.CHANGE_LINK_COLOR)
	popup.add_item("Switch conf./prob.", MenuItem.SWITCH_LINK)
	popup.add_item("Delete link", MenuItem.DELETE_LINK)
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_item("Remove warning", MenuItem.REMOVE_WARNING)
	
	popup.id_pressed.connect(_handle_popup)
	submenu1.id_pressed.connect(_handle_submenu.bind(0))
	submenu2.id_pressed.connect(_handle_submenu.bind(1))
	submenu3.id_pressed.connect(_handle_submenu.bind(2))
	
	top_bar.settings.connect(func(): settings.emit())
	top_bar.quit.connect(func(): quit.emit())
	
	Globals.mouse_entered_card.connect(_mouse_entered_card)
	Globals.mouse_exited_card.connect(_mouse_exited_card)
	Globals.card_left_click.connect(_click_on_card)
	Globals.card_right_click.connect(_popup_menu)
	Globals.card_double_click.connect(_double_click_on_card)
	Globals.mouse_entered_link.connect(_mouse_entered_link)
	Globals.mouse_exited_link.connect(_mouse_exited_link)
	Globals.link_right_click.connect(_popup_menu)
	Globals.pin_left_click.connect(_click_on_pin)

	Globals.dialog_overlay.pre_dialog.connect(_pause_input_handling)
	Globals.dialog_overlay.post_dialog.connect(_resume_input_handling)

	tree_exiting.connect(_detach_cards)
	GameState.case_changed.connect(_on_case_changed)
	GameState.location_changed.connect(_update_player_location_info)
	GameState.addiction_changed.connect(_on_addiction_changed)

	_update_player_location_info()

func _unhandled_input(event: InputEvent):
	if _drag_state == DragState.DRAGGING:
		if event is InputEventMouseMotion:
			_drag(event.global_position)
		elif event is InputEventMouseButton and not event.pressed:
			_stop_drag(event.global_position)
			_drag_state = DragState.NONE
			_clicked_pin = null
		elif event.is_action_pressed("Escape"):
			get_viewport().set_input_as_handled()
			_abort_drag()
			_drag_state = DragState.NONE
			_clicked_pin = null
	elif _drag_state == DragState.CLICKED:
		if event is InputEventMouseMotion:
			_unblock_info_box()
			if _start_drag():
				Globals.dragging = true
				_drag_state = DragState.DRAGGING
			else:
				_drag_state = DragState.NONE
				_clicked_pin = null
		elif event is InputEventMouseButton and not event.pressed:
			_drag_state = DragState.NONE
			_clicked_pin = null
	elif _drag_state == DragState.LINKING:
		if event is InputEventMouseMotion:
			_dst_pin.global_position = event.global_position
		elif event.is_action_pressed("Escape"):
			get_viewport().set_input_as_handled()
			_abort_linking()
		elif event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
			_stop_linking(event.global_position)
	else:
		if _current_card == null and event.is_action_pressed("Left_Click"):
			_unblock_info_box()

func _mouse_entered_card(card: Card):
	if _input_paused:
		return
	if _drag_state == DragState.NONE and card != _current_card:
		if _current_card:
			_current_card.set_highlighted(false)
		card.set_highlighted(true)
		_current_card = card
		_update_info_box()
	elif _drag_state == DragState.DRAGGING and _clicked_pin and not card.is_stacked():
		_set_drop_target(card)
	elif _drag_state == DragState.LINKING:
		_set_drop_target(card)

func _mouse_exited_card(card: Card):
	if _input_paused:
		return

	# note that, for some reason, when the mouse moves directly from one card to
	# another, the mouse_entered signal for the new card is received BEFORE the
	# mouse_exited signal for the old one

	if _drag_state == DragState.NONE:
		card.set_highlighted(false)
		if card == _current_card:
			_current_card = null
			_update_info_box()
	elif ((_drag_state == DragState.DRAGGING and _clicked_pin)
		or _drag_state == DragState.LINKING):
		if card == _drop_target:
			_set_drop_target(null)

func _click_on_card(global_pos: Vector2, card: Card):
	if _input_paused:
		return
	_mouse_entered_card(card)
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos
	_unblock_info_box()
	_block_info_box()

func _double_click_on_card(card: Card):
	if _input_paused:
		return
	if not card.is_stacked():
		card.expand_or_reduce()
	_unblock_info_box()

func _click_on_pin(global_pos: Vector2, pin: Pin):
	if _input_paused:
		return
	_clicked_pin = pin
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos

func _mouse_entered_link(link: Link):
	if _input_paused:
		return
	if _drag_state == DragState.DRAGGING and _clicked_pin:
		_set_drop_target(link)
	elif _drag_state == DragState.LINKING:
		_set_drop_target(link)

func _mouse_exited_link(_link: Link):
	if _input_paused:
		return
	if _drag_state == DragState.DRAGGING and _clicked_pin:
		_set_drop_target(null)
	elif _drag_state == DragState.LINKING:
		_set_drop_target(null)

func _start_drag() -> bool:
	if _clicked_pin:
		return _start_drag_pin()
	else:
		return _start_drag_card()

func _start_drag_card() -> bool:
	_drag_local_init_pos = _current_card.position
	_drag_global_init_pos = _current_card.global_position
	_current_card.start_drag()

	# turn on the drag & drop line that connects the initial and current
	# mouse positions

	drag_drop_line.point1 = _drag_click_pos
	drag_drop_line.point2 = _drag_click_pos
	drag_drop_line.show_line()
	Globals.push_mouse_cursor(Globals.MouseCursor.CIRCLE)

	# increase the Z index of any links connected to the card being dragged, so
	# that they, too, are drawn on top of everything else (Card.start_drag()
	# does that for the card itself)

	for link in _current_card.find_links():
		link.pause_collisions()
		link.raise()
		_drag_links.append(link)

	return true

func _start_drag_pin() -> bool:

	# don't allow the user to drag a pin whose associated link is hidden

	var link = _clicked_pin.get_link_reference()
	if not (link and link.visible):
		return false

	_set_drop_target(_clicked_pin.backing)
	_drag_local_init_pos = _clicked_pin.position
	_drag_global_init_pos = _clicked_pin.global_position
	_clicked_pin.z_index += 1

	# temporarily disable the pin and link's colliders, otherwise they will
	# block card enter/exit events, because they are always under the mouse
	# while dragging

	_clicked_pin.pause_collisions()

	# increase the Z index of the link connected to the pin being dragged

	link.pause_collisions()
	link.raise()
	_drag_links.append(link)

	return true

func _drag(global_pos: Vector2):
	if _clicked_pin:
		_drag_pin(global_pos)
	else:
		_drag_card(global_pos)

func _drag_card(global_pos: Vector2):
	_current_card.global_position = \
		(_drag_global_init_pos + (global_pos - _drag_click_pos)).round()
	drag_drop_line.point2 = global_pos

func _drag_pin(global_pos: Vector2):
	_clicked_pin.global_position = \
		(_drag_global_init_pos + (global_pos - _drag_click_pos)).round()

func _abort_drag():
	if _clicked_pin:
		_abort_drag_pin()
	else:
		_abort_drag_card()

func _abort_drag_card():
	Globals.pop_mouse_cursor()
	drag_drop_line.hide_line()
	var card = _current_card
	var tween = create_tween()
	tween.tween_property(card, "position", _drag_local_init_pos, 0.15)
	await tween.finished
	_stuff_to_do_when_drag_ends(card)

func _abort_drag_pin():
	if _clicked_pin:
		var tween = create_tween()
		tween.tween_property(_clicked_pin, "position", _drag_local_init_pos, 0.15)
	_stuff_to_do_when_drag_ends(null)

func _stop_drag(global_pos: Vector2):
	if _clicked_pin:
		_stop_drag_pin(global_pos)
	else:
		_stop_drag_card(global_pos)

func _stop_drag_card(global_pos: Vector2):
	var in_reserve: bool
	if _is_in_reserve(global_pos):
		in_reserve = true
		if _current_card.get_parent() == reserve:
			_abort_drag_card()
			return
	elif _is_in_playground(global_pos):
		in_reserve = false
	else:
		_abort_drag_card()
		return

	Globals.pop_mouse_cursor()
	drag_drop_line.hide_line()

	# wait for animation to finish before call to set_expanded() (issue #74)
	var dragged_card = _current_card
	await _stuff_to_do_when_drag_ends(_current_card)

	if in_reserve:
		dragged_card.set_expanded(true)
		dragged_card.reparent(reserve, false)
	else:
		# card is allowed to overshoot left and top edges by 10 pixels at most
		var corner = cards.global_position
		var pos = dragged_card.global_position.max(corner - Vector2(10, 10))
		dragged_card.global_position = pos.round()
		dragged_card.reparent(cards)

func _stop_drag_pin(global_pos: Vector2):
	if not _drop_target:
		_abort_drag_pin()
		return

	# the link the dragged pin is connected to

	var link = _drag_links[0]

	# user dropped the pin on a card

	if _drop_target is Card:

		# abort if the card has no unused pins

		var target_pin = _drop_target.find_closest_unused_pin(global_pos)
		if target_pin < 0:
			_abort_drag_pin()
			return

		# don't allow both endpoints of a link to be on the same card

		var other_card
		if _clicked_pin == link.pin1:
			other_card = link.pin2.backing
		else:
			other_card = link.pin1.backing

		if _drop_target == other_card:
			_abort_drag_pin()
			return

		_stuff_to_do_when_drag_ends(null)
		_clicked_pin.move_to_card(_drop_target, target_pin)

	# user dropped the pin on a link

	else:

		# abort if the pin's other endpoint is also a link (links must have a
		# card for at least one endpoint)

		var other_pin: Pin
		if link.pin1 == _clicked_pin:
			other_pin = link.pin2
		else:
			other_pin = link.pin1

		if other_pin.backing is Link:
			_abort_drag_pin()
			return

		_stuff_to_do_when_drag_ends(null)
		_clicked_pin.move_to_link_at(_drop_target, global_pos)

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	for link in _drag_links:
		link.resume_collisions()
		link.lower()
	_drag_links.clear()
	if dragged_card:
		await dragged_card.stop_drag()
	if _clicked_pin:
		_clicked_pin.z_index -= 1
		_clicked_pin.resume_collisions()
	Globals.dragging = false
	Globals.set_mouse_cursor(Globals.MouseCursor.ARROW)

func _is_in_playground(global_pos: Vector2):
	var rect = Rect2(cards.global_position, cards.size)
	return rect.has_point(global_pos)

func _is_in_reserve(global_pos: Vector2):
	var rect = Rect2(reserve.global_position, reserve.size)
	return rect.has_point(global_pos)

func _start_linking(card: Card, type: Link.Type, is_confirmed: bool):
	var src_loc = card.find_closest_unused_pin(popup.position)
	if src_loc < 0:
		return

	_src_pin = pin_scene.instantiate()
	cards.add_child(_src_pin)
	_src_pin.card_location = src_loc as Pin.Location
	_src_pin.backing = card

	_dst_pin = pin_scene.instantiate()
	cards.add_child(_dst_pin)
	_dst_pin.global_position = get_global_mouse_position()
	# if the pin is pickable, it hides cards' mouse enter/exit events
	_dst_pin.pause_collisions()

	_new_link = link_scene.instantiate()
	_new_link.type = type
	_new_link.status = Link.Status.CONFIRMED if is_confirmed else Link.Status.PROBABLE
	_new_link.pin1 = _src_pin
	_new_link.pin2 = _dst_pin
	# if the link is pickable, it hides cards' mouse enter/exit events
	_new_link.pause_collisions()
	cards.add_child(_new_link)
	_new_link.raise()

	_drag_state = DragState.LINKING
	Globals.dragging = true

func _abort_linking():
	_new_link.queue_free()
	_src_pin.queue_free()
	_dst_pin.queue_free()
	_drag_state = DragState.NONE
	Globals.dragging = false
	Globals.set_mouse_cursor(Globals.MouseCursor.ARROW)

func _stop_linking(global_pos: Vector2):

	# user dropped the pin on nothing, or there is already a link of the given
	# type from the source card to the drop target, or both the source and the
	# target are the same card or link, or they are both links

	if not _can_link(_src_pin.backing, _drop_target, _new_link.type):
		_abort_linking()
		return

	# user dropped the pin on a card

	if _drop_target is Card:

		# abort if the card has no unused pins

		var dst_loc = _drop_target.find_closest_unused_pin(global_pos)
		if dst_loc < 0:
			_abort_linking()
			return

		_dst_pin.move_to_card(_drop_target, dst_loc as Pin.Location)

	# user dropped the pin on a link

	else:
		_dst_pin.move_to_link_at(_drop_target, global_pos)

	_dst_pin.resume_collisions()
	_new_link.resume_collisions()
	_new_link.lower()

	var case = GameState.get_current_case()
	if case:
		case.add_link(_new_link)

	_drag_state = DragState.NONE
	Globals.dragging = false
	Globals.set_mouse_cursor(Globals.MouseCursor.ARROW)

#
# Sets the "drop target" while creating a new link or dragging an existing pin.
# The mouse cursor is set to reflect whether or not the new drop target is
# valid, that is, whether the new link can be created or the pin moved there.
#
func _set_drop_target(target: Node2D):
	_drop_target = target
	var ok = true

	if _drop_target:

		# dragging an existing pin

		if _clicked_pin:
			if _clicked_pin.backing == _drop_target:
				ok = true
			else:
				var link = _clicked_pin.get_link_reference()
				var src
				if _clicked_pin == link.pin1:
					src = link.pin2.backing
				else:
					src = link.pin1.backing
				ok = _can_link(src, _drop_target, link.type)

		# creating a new link

		else:
			ok = _can_link(_src_pin.backing, _drop_target, _new_link.type)

	if ok:
		Globals.set_mouse_cursor(Globals.MouseCursor.CIRCLE)
	else:
		Globals.set_mouse_cursor(Globals.MouseCursor.CROSS)

#
# Returns true if a link of the given type can be created between source and
# target.
#
func _can_link(source: Node2D, target: Node2D, link_type: Link.Type):
	return source and target and Link.is_link_valid(source, target, link_type)

func _popup_menu(pos: Vector2, node: Node2D):
	if _input_paused:
		return
	if node is Card and node.is_stacked():
		return

	var player_is_apt = (
		GameState.player.physical >= 0 and
		GameState.player.mental >= 0 and
		GameState.player.health >= 0)

	var index = popup.get_item_index(MenuItem.INVESTIGATION)
	popup.set_item_disabled(
		index,
		not player_is_apt
		or node is not LocationCard
		or node.has_been_investigated_today())

	var link_create_ids = [
		MenuItem.CREATE_CONF_LINK,
		MenuItem.CREATE_PROB_LINK
	]

	for id in link_create_ids:
		index = popup.get_item_index(id)
		if node is Card:
			popup.set_item_disabled(index, false)
			var submenu = popup.get_item_submenu_node(index)
			for i in submenu.item_count:
				var link_type = submenu.get_item_id(i)
				submenu.set_item_disabled(
					i, not Link.is_link_valid(node, null, link_type))
		else:
			popup.set_item_disabled(index, true)

	var link_mod_ids = [
		MenuItem.CHANGE_LINK_COLOR,
		MenuItem.SWITCH_LINK,
		MenuItem.DELETE_LINK
	]

	for id in link_mod_ids:
		index = popup.get_item_index(id)
		popup.set_item_disabled(index, node is not Link or node.blocked)

	# player cannot change a link to a type for which there is already a link

	var change_submenu_index = popup.get_item_index(MenuItem.CHANGE_LINK_COLOR)
	if not popup.is_item_disabled(change_submenu_index):
		var submenu = popup.get_item_submenu_node(change_submenu_index)
		for i in submenu.item_count:
			var link_type = submenu.get_item_id(i)
			submenu.set_item_disabled(
				i, link_type == node.type or not Link.is_link_valid(
					node.pin1.backing, node.pin2.backing, link_type))

	_popup_node = node
	popup.popup(Rect2i(pos, Vector2i()))

func _handle_popup(id: int):
	match id:
		MenuItem.DIALOGUE:
			print("start dialogue")
		MenuItem.INVESTIGATION:
			GameState.attempt_investigation(_popup_node)
		MenuItem.SWITCH_LINK:
			if _popup_node is Link:
				if _popup_node.status == Link.Status.CONFIRMED:
					_popup_node.status = Link.Status.PROBABLE
				else:
					_popup_node.status = Link.Status.CONFIRMED
		MenuItem.DELETE_LINK:
			if _popup_node is Link:
				var case = GameState.get_current_case()
				if case:
					case.remove_link(_popup_node)
				_popup_node.queue_free()
				_popup_node = null
		MenuItem.REMOVE_WARNING:
			print("remove warning")

func _handle_submenu(id: int, submenu: int):
	match submenu:
		0:
			if _popup_node is Card:
				_start_linking(_popup_node, id as Link.Type, true)
		1:
			if _popup_node is Card:
				_start_linking(_popup_node, id as Link.Type, false)
		2:
			if _popup_node is Link:
				_popup_node.type = id

#
# Called before a (modal) dialog is displayed: all input handling is paused
# until it is done.
#
func _pause_input_handling():
	_input_paused = true
	set_process_input(false)
	reserve.set_process_input(false)

#
# Called when a (modal) dialog is hidden to resume input handling.
#
func _resume_input_handling():
	_input_paused = false
	set_process_input(true)
	reserve.set_process_input(true)

func _on_case_changed():
	_detach_cards()
	var case = GameState.get_current_case()
	if case:
		populate(case)

##
## Populates the scene with the given cards and links.
##
func populate(case: Case):
	if case.is_layout_needed:
		for card in case.get_revealed_cards():
			if card is NpcCard or \
				(card is LocationCard and \
				 card.location_status == LocationCard.LocationStatus.CRIME_SCENE):
				cards.add_child(card)
			else:
				reserve.add_child(card)
		_layout_cards()
		case.is_layout_needed = false
	else:
		for card in case.get_revealed_cards():
			if card.was_stacked():
				reserve.add_child(card)
			else:
				cards.add_child(card)

	for link in case.get_links():
		cards.add_child(link)
		cards.add_child(link.pin1)
		cards.add_child(link.pin2)

#
# Lays out the starting cards in a new game.
#
func _layout_cards():
	var top_left = cards.global_position
	var bottom_right = top_left + cards.size
	var npc_pos = top_left
	var other_pos = top_left + Vector2(round(cards.size.x * 0.35), 0)
	var shift = Vector2(20, 40)

	for child in cards.get_children():
		if child is NpcCard and child.npc_status != NpcCard.NpcStatus.NONE:
			child.global_position = npc_pos
			npc_pos += shift
			if npc_pos.y > bottom_right.y - Card.size.y:
				npc_pos.y = top_left.y
		elif child is Card:
			child.global_position = other_pos
			other_pos += shift
			if other_pos.y > bottom_right.y - Card.size.y:
				other_pos.y = top_left.y
			

#
# Removes cards and links from the scene without deleting them, because
# GameState holds references to them.
#
func _detach_cards():
	for child in cards.get_children():
		cards.remove_child(child)
	for child in reserve.get_children():
		reserve.remove_child(child)

func _on_addiction_changed():
	var player = GameState.player
	if player.addiction > -5 and player.addiction < 5:
		return
	var die = (
		player.health <= 1
		or absi(player.emotion) >= 4
		or randi() % 10 > player.health)
	await Globals.dialog_overlay.show_addiction_message(die)
	if die:
		player.die()
	else:
		player.addiction = 4 * signi(player.addiction)
		player.health -= 1
		player.emotion += signi(player.emotion)

func _update_player_location_info():
	var location = GameState.get_player_location()
	var card: LocationCard

	# attach the player locator symbol to the appropriate card

	if location == GameState.PlayerLocation.OTHER:
		card = GameState.get_player_location_card()
		$Player_Locator.attach_to_card(card)
	else:
		$Player_Locator.detach_from_card()
		$Player_Locator.hide()

	# update player location in the upper right corner

	var loc_text = ""

	match location:
		GameState.PlayerLocation.OFFICE:
			loc_text = "In the office"
		GameState.PlayerLocation.INVESTIGATION_CENTER:
			loc_text = "At the investigation center"
		GameState.PlayerLocation.DOCTOR:
			loc_text = "At Doctor F's"
		GameState.PlayerLocation.ROWENA:
			loc_text = "At Rowena's"
		GameState.PlayerLocation.WARRANT_DESK:
			loc_text = "At the warrant desk"
		GameState.PlayerLocation.PRISON:
			loc_text = "In jail"
		GameState.PlayerLocation.OTHER:
			loc_text = card.get_display_name()

	location_bar.text = loc_text

	# show lots of information about the current location in the box in the
	# lower left corner

	_update_info_box()

#
# Blocks the info box so that it shows information about whichever card is
# current now, until _unblock_info_box() is called.
#
func _block_info_box():
	if _current_card and _current_card != _blocked_info_card:
		_blocked_info_card = _current_card
		_blocked_info_card.set_locked(true)
		Globals.lock_sound.play()

#
# Unblocks the info box, if it was previously blocked by a call to
# _block_info_box().
#
func _unblock_info_box():
	if _blocked_info_card:
		_blocked_info_card.set_locked(false)
		_blocked_info_card = null
		_update_info_box()
		Globals.unlock_sound.play()

#
# Updates the contents of the info box with info about the current card, if
# there is one, or about the player's location, if not. Does nothing if the
# info box has been blocked by a call to _block_info_box().
#
func _update_info_box():
	if not _blocked_info_card:
		if _current_card:
			info_box.show_card(_current_card)
		else:
			info_box.show_location(
				GameState.get_player_location(),
				GameState.get_player_location_card())
