extends Node2D

@onready var cards: Node2D = $Cards
@onready var links: Node2D = $Links
@onready var reserve: Node2D = $Reserve_Cards
@onready var drag_drop_line: Node2D = $Drag_Drop_Line
@onready var popup: PopupMenu = $Mask_Card_Playground/Popup_Menu
@onready var playground_shape: CollisionShape2D = $Mask_Card_Playground/Colliders/Playground_Collider/Playground

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
var _clicked_pin: Pin_Small

# the card the mouse is over, while a pin is being dragged
var _target_card: Card

# has a card or pin been clicked, and is possibly being dragged?
enum DragState { NONE, CLICKED, DRAGGING }
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
			_start_drag()
			_drag_state = DragState.DRAGGING
		elif event is InputEventMouseButton and not event.pressed:
			_drag_state = DragState.NONE
			_clicked_pin = null

func _mouse_entered_card(card: Card):
	if _drag_state == DragState.NONE and card != _current_card:
		if _current_card:
			_current_card.set_highlighted(false)
		card.set_highlighted(true)
		_current_card = card
		print("show info about card: ", card.card_name)
	elif _drag_state == DragState.DRAGGING and _clicked_pin and not card.is_stacked:
		_target_card = card

func _mouse_exited_card(card: Card):
	if _drag_state == DragState.NONE:
		card.set_highlighted(false)
		if _current_card == card:
			_current_card = null
	elif _drag_state == DragState.DRAGGING and _clicked_pin:
		_target_card = null

func _click_on_card(global_pos: Vector2, card: Card):
	_mouse_entered_card(card)
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos

func _click_on_pin(global_pos: Vector2, card: Card, pin: Card.PinLocation):
	_clicked_pin = card.get_pin(pin)
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos

func _start_drag():
	Globals.dragging = true
	if _clicked_pin:
		_start_drag_pin()
	else:
		_start_drag_card()

func _start_drag_card():
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

	for link in links.get_children():
		if link is Link and (link.card1 == _current_card or link.card2 == _current_card):
			_raise_link(link)
			_drag_links.append(link)

func _start_drag_pin():
	_target_card = _clicked_pin.get_card()
	_drag_local_init_pos = _clicked_pin.position
	_drag_global_init_pos = _clicked_pin.global_position
	_clicked_pin.z_index += 1

	# temporarily disable the pin's collider, otherwise it will block card
	# enter/exit events, because it is always under the mouse while dragged

	_clicked_pin.get_collider().input_pickable = false

	# increase the Z index of the link connected to the pin being dragged

	for link in links.get_children():
		if link is Link and link.is_connected_to_pin(_clicked_pin):
			_raise_link(link)
			_drag_links.append(link)

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
	var target_pin_index
	if _target_card:
		target_pin_index = _target_card.find_closest_hidden_pin(global_pos)
	else:
		target_pin_index = Card.PinLocation.NONE

	if target_pin_index == Card.PinLocation.NONE:
		_abort_drag_pin()
	else:
		var link = _drag_links[0]
		var other_card
		if _clicked_pin == link.card1.get_pin(link.pin1):
			other_card = link.card2
		else:
			other_card = link.card1
		if _target_card == other_card:
			_abort_drag_pin()
		else:
			_stuff_to_do_when_drag_ends(null)
			_clicked_pin.position = _drag_local_init_pos
			if other_card == link.card1:
				link.set_endpoint2(_target_card, target_pin_index)
			else:
				link.set_endpoint1(_target_card, target_pin_index)

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	for link in _drag_links:
		_lower_link(link)
	_drag_links.clear()
	if dragged_card:
		dragged_card.stop_drag()
	if _clicked_pin:
		_clicked_pin.z_index -= 1
		_clicked_pin.get_collider().input_pickable = true
	Globals.dragging = false

func _raise_link(link: Link):
	link.z_index += 1
	link.card1.get_pin(link.pin1).z_index += 1
	link.card2.get_pin(link.pin2).z_index += 1

func _lower_link(link: Link):
	link.z_index -= 1
	link.card1.get_pin(link.pin1).z_index -= 1
	link.card2.get_pin(link.pin2).z_index -= 1

func _is_in_playground(global_pos: Vector2):
	var local_rect = playground_shape.shape.get_rect()
	var local_pos = playground_shape.to_local(global_pos)
	return local_rect.has_point(local_pos)

func _is_in_reserve(global_pos: Vector2):
	var rect = Rect2(reserve.global_position, reserve.size)
	return rect.has_point(global_pos)

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
				print("create confirmed link")
		1:
			if _popup_node is Card:
				print("create probable link")
		2:
			if _popup_node is Link:
				_popup_node.type = id
