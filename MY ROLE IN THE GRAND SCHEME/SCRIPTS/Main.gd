extends Node2D

@onready var cards: Node2D = $Cards
@onready var pins: Node2D = $Pins
@onready var links: Node2D = $Links
@onready var reserve: Node2D = $Reserve_Cards
@onready var drag_drop_line: Node2D = $Drag_Drop_Line
@onready var popup: PopupMenu = $Mask_Card_Playground/Popup_Menu
@onready var playground_shape: CollisionShape2D = $Mask_Card_Playground/Colliders/Playground_Collider/Playground
@onready var pin_scene: PackedScene = preload("res://SCENES/Pin_Small.tscn")
@onready var link_scene: PackedScene = preload("res://SCENES/Link.tscn")

enum MenuItem {
	DIALOGUE,
	INVESTIGATION,
	SWITCH_LINK,
	DELETE_LINK,
	REMOVE_WARNING
}

# highlighted card
var _current_card: Card

# the visible pin which has been clicked and not yet released
var _clicked_pin: Pin

# the card or link the mouse is over, while a pin is being dragged
var _drop_target: Node2D

# has something been clicked on, or is something being dragged?
enum DragState {
	NONE,		# nothing is going on
	CLICKED,	# a card or a pin has been clicked but is not being dragged yet
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

func _ready():
	var submenu1 = popup.get_child(0)
	var submenu2 = submenu1.duplicate()
	var submenu3 = submenu1.duplicate()
	popup.add_child(submenu2)
	popup.add_child(submenu3)
	
	popup.add_item("Dialogue", MenuItem.DIALOGUE)
	popup.add_item("Investigation", MenuItem.INVESTIGATION)
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_submenu_node_item("Create conf. link", submenu1)
	popup.add_submenu_node_item("Create prob. link", submenu2)
	popup.add_submenu_node_item("Change link color", submenu3)
	popup.add_item("Switch conf./prob.", MenuItem.SWITCH_LINK)
	popup.add_item("Delete link", MenuItem.DELETE_LINK)
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_item("Remove warning", MenuItem.REMOVE_WARNING)
	
	popup.id_pressed.connect(_handle_popup)
	submenu1.id_pressed.connect(_handle_submenu.bind(0))
	submenu2.id_pressed.connect(_handle_submenu.bind(1))
	submenu3.id_pressed.connect(_handle_submenu.bind(2))
	
	Globals.mouse_entered_card.connect(_mouse_entered_card)
	Globals.mouse_exited_card.connect(_mouse_exited_card)
	Globals.card_left_click.connect(_click_on_card)
	Globals.card_right_click.connect(_popup_menu)
	Globals.mouse_entered_link.connect(_mouse_entered_link)
	Globals.mouse_exited_link.connect(_mouse_exited_link)
	Globals.link_right_click.connect(_popup_menu)
	Globals.pin_left_click.connect(_click_on_pin)

func _input(event: InputEvent):
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

func _mouse_entered_card(card: Card):
	if _drag_state == DragState.NONE and card != _current_card:
		if _current_card:
			_current_card.set_highlighted(false)
		card.set_highlighted(true)
		_current_card = card
		print("show info about card: ", card.card_name)
	elif _drag_state == DragState.DRAGGING and _clicked_pin and not card.is_stacked:
		_drop_target = card
	elif _drag_state == DragState.LINKING:
		_drop_target = card

func _mouse_exited_card(card: Card):
	if _drag_state == DragState.NONE:
		card.set_highlighted(false)
		if _current_card == card:
			_current_card = null
	elif _drag_state == DragState.DRAGGING and _clicked_pin:
		_drop_target = null
	elif _drag_state == DragState.LINKING:
		_drop_target = null

func _click_on_card(global_pos: Vector2, card: Card):
	_mouse_entered_card(card)
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos

func _click_on_pin(global_pos: Vector2, pin: Pin):
	_clicked_pin = pin
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos

func _mouse_entered_link(link: Link):
	_drop_target = link

func _mouse_exited_link(_link: Link):
	_drop_target = null

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

	# increase the Z index of any links connected to the card being dragged, so
	# that they, too, are drawn on top of everything else (Card.start_drag()
	# does that for the card itself)

	for link in _find_links_to_card(_current_card):
		link.pause_collisions()
		link.raise()
		_drag_links.append(link)

	return true

func _start_drag_pin() -> bool:

	# don't allow the user to drag a pin whose associated link is hidden

	var link = _find_link_to_pin(_clicked_pin)
	if not (link and link.visible):
		return false
	
	_drop_target = _clicked_pin.card
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

func _find_links_to_card(card: Card) -> Array[Link]:
	var ret: Array[Link]
	for link in links.get_children():
		if (link is Link and (link.pin1.card == card or link.pin2.card == card)):
			ret.append(link)
	return ret

func _find_link_to_pin(pin: Pin) -> Link:
	for link in links.get_children():
		if link is Link and (link.pin1 == pin or link.pin2 == pin):
			return link
	return null

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
	else:
		print("_clicked_pin is null??")
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
	elif _is_in_playground(global_pos):
		in_reserve = false
	else:
		_abort_drag_card()
		return

	drag_drop_line.hide_line()
	_stuff_to_do_when_drag_ends(_current_card)

	if in_reserve:
		_current_card.is_stacked = true
		_current_card.set_expanded(true)
		_current_card.reparent(reserve, false)
	else:
		_current_card.is_stacked = false
		# card is allowed to overshoot left and top edges by 10 pixels at most
		var corner = (playground_shape.get_global_transform() *
					  playground_shape.shape.get_rect().position)
		var pos = _current_card.global_position.max(corner - Vector2(10, 10))
		_current_card.global_position = pos.round()
		_current_card.reparent(cards)

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
			other_card = link.pin2.card
		else:
			other_card = link.pin1.card

		if _drop_target == other_card:
			_abort_drag_pin()
			return

		_stuff_to_do_when_drag_ends(null)
		_clicked_pin.move_to_card(_drop_target, target_pin)

	# user dropped the pin on a link

	else:

		# abort if the link already has a pin in the middle (for now we only
		# allow one, because it is always displayed at the midpoint)

		if _drop_target.has_follower_pins():
			_abort_drag_pin()
			return

		# abort if the pin's other endpoint is also a link (links must have a
		# card for at least one endpoint)

		var other_pin: Pin
		if link.pin1 == _clicked_pin:
			other_pin = link.pin2
		else:
			other_pin = link.pin1

		if other_pin.type == Pin.PinType.LINK:
			_abort_drag_pin()
			return

		_stuff_to_do_when_drag_ends(null)
		_clicked_pin.move_to_link(_drop_target)

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	for link in _drag_links:
		link.resume_collisions()
		link.lower()
	_drag_links.clear()
	if dragged_card:
		dragged_card.stop_drag()
	if _clicked_pin:
		_clicked_pin.z_index -= 1
		_clicked_pin.resume_collisions()
	Globals.dragging = false

func _is_in_playground(global_pos: Vector2):
	var local_rect = playground_shape.shape.get_rect()
	var local_pos = playground_shape.to_local(global_pos)
	return local_rect.has_point(local_pos)

func _is_in_reserve(global_pos: Vector2):
	var rect = Rect2(reserve.global_position, reserve.size)
	return rect.has_point(global_pos)

func _start_linking(card: Card, type: Link.Type, is_confirmed: bool):
	var src_loc = card.find_closest_unused_pin(popup.position)
	if src_loc < 0:
		return

	_src_pin = pin_scene.instantiate()
	_src_pin.location = src_loc as Pin.Location
	_src_pin.card = card
	pins.add_child(_src_pin)

	_dst_pin = pin_scene.instantiate()
	_dst_pin.global_position = get_global_mouse_position()
	# if the pin is pickable, it hides cards' mouse enter/exit events
	_dst_pin.pause_collisions()
	pins.add_child(_dst_pin)

	_new_link = link_scene.instantiate()
	_new_link.type = type
	_new_link.is_confirmed = is_confirmed
	_new_link.pin1 = _src_pin
	_new_link.pin2 = _dst_pin
	# if the link is pickable, it hides cards' mouse enter/exit events
	_new_link.pause_collisions()
	links.add_child(_new_link)
	_new_link.raise()

	_drag_state = DragState.LINKING
	Globals.dragging = true

func _abort_linking():
	_new_link.queue_free()
	_src_pin.queue_free()
	_dst_pin.queue_free()
	_drag_state = DragState.NONE
	Globals.dragging = false

func _stop_linking(global_pos: Vector2):
	if not _drop_target:
		_abort_linking()
		return

	# user dropped the pin on a card

	if _drop_target is Card:

		# abort if the card has no unused pins

		var dst_loc = _drop_target.find_closest_unused_pin(global_pos)
		if dst_loc < 0:
			_abort_linking()
			return

		# don't allow both endpoints of a link to be on the same card

		if _drop_target == _src_pin.card:
			_abort_linking()
			return

		_dst_pin.move_to_card(_drop_target, dst_loc as Pin.Location)

	# user dropped the pin on a link

	else:

		# abort if the link already has a pin in the middle (for now we only
		# allow one, because it is always displayed at the midpoint)

		if _drop_target.has_follower_pins():
			_abort_linking()
			return

		# abort if the pin's other endpoint is also a link (links must have a
		# card for at least one endpoint)

		if _src_pin.type == Pin.PinType.LINK:
			_abort_linking()
			return

		_dst_pin.move_to_link(_drop_target)

	_dst_pin.resume_collisions()
	_new_link.resume_collisions()
	_new_link.lower()

	_drag_state = DragState.NONE
	Globals.dragging = false

func _popup_menu(pos: Vector2, node: Node2D):
	if node is Card:
		if node.is_stacked:
			return
		print("popup menu for card: ", node.card_name)
	elif node is Link:
		print("popup menu for link: ", node.get_name())
	else:
		print("popup menu for node: ", node.get_name())
	_popup_node = node
	popup.popup(Rect2i(pos, Vector2i()))

func _handle_popup(id: int):
	match id:
		MenuItem.DIALOGUE:
			print("start dialogue")
		MenuItem.INVESTIGATION:
			print("start investigation")
		MenuItem.SWITCH_LINK:
			if _popup_node is Link:
				_popup_node.is_confirmed = not _popup_node.is_confirmed
		MenuItem.DELETE_LINK:
			if _popup_node is Link:
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
