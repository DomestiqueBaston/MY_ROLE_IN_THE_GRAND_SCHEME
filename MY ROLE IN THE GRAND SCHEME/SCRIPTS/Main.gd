extends Node2D

@onready var cards: Node2D = $TMP_1/Main_Playmat/Cards
@onready var links: Node2D = $TMP_1/Main_Playmat/Links
@onready var reserve: Node2D = $Mask_Card_Playground/TMP_2/Reserve_Cards
@onready var popup: PopupMenu = $Mask_Card_Playground/Popup/Main_Menu
@onready var playground_shape: CollisionShape2D = $Mask_Card_Playground/Colliders/Playground_Collider/Playground
@onready var reserve_shape: CollisionShape2D = $Mask_Card_Playground/Colliders/Reserve_Collider/Reserve

# highlighted card
var _current_card: Card

# has highlighted card been clicked, or is it being dragged?
enum DragState { NONE, CLICKED, DRAGGING }
var _drag_state: DragState = DragState.NONE

# current card's parent node when dragging began
var _drag_parent: Node

# current card's index in its parent when dragging began
var _drag_index: int

# current card's position in local coordinates when dragging began
var _drag_local_init_pos: Vector2

# current card's position in global coordinates when dragging began
var _drag_global_init_pos: Vector2

# where the user clicked, in global coordinates, to initiate dragging
var _drag_click_pos: Vector2

func _ready():
	popup.add_item("Dialogue")
	popup.add_item("Investigation")
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_submenu_node_item("Create conf. link", $Mask_Card_Playground/Popup/Main_Menu/Sub_Menu)
	popup.add_submenu_node_item("Create prob. link", $Mask_Card_Playground/Popup/Main_Menu/Sub_Menu)
	popup.add_submenu_node_item("Change link color", $Mask_Card_Playground/Popup/Main_Menu/Sub_Menu)
	popup.add_item("Switch conf./prob.")
	popup.add_item("Delete link")
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_item("Throw card away")
	
	Globals.mouse_entered_card.connect(_mouse_entered_card)
	Globals.mouse_exited_card.connect(_mouse_exited_card)
	Globals.card_left_click.connect(_click_on_card)
	Globals.card_right_click.connect(_popup_menu)
	Globals.link_right_click.connect(_popup_menu)

func _input(event: InputEvent):
	if _drag_state == DragState.DRAGGING:
		if event is InputEventMouseMotion:
			_drag(event.global_position)
		elif event is InputEventMouseButton and not event.pressed:
			_stop_drag(event.global_position)
			_drag_state = DragState.NONE
		elif event.is_action_pressed("Escape"):
			get_viewport().set_input_as_handled()
			_abort_drag()
			_drag_state = DragState.NONE
	elif _drag_state == DragState.CLICKED:
		if event is InputEventMouseMotion:
			_start_drag()
			_drag_state = DragState.DRAGGING
		elif event is InputEventMouseButton and not event.pressed:
			_drag_state = DragState.NONE

func _popup_menu(pos: Vector2, node: Node2D):
	if node is Card:
		if node.is_stacked:
			return
		print("popup menu for card: ", node.card_name)
	elif node is Link:
		print("popup menu for link: ", node.get_name())
	else:
		print("popup menu for node: ", node.get_name())
	popup.popup(Rect2i(pos, Vector2i()))

func _mouse_entered_card(card: Card):
	if _drag_state == DragState.NONE and card != _current_card:
		if _current_card:
			_current_card.set_highlighted(false)
		card.set_highlighted(true)
		_current_card = card
		print("show info about card: ", card.card_name)

func _mouse_exited_card(card: Card):
	if _drag_state == DragState.NONE:
		card.set_highlighted(false)
		if _current_card == card:
			_current_card = null

func _click_on_card(global_pos: Vector2, card: Card):
	_mouse_entered_card(card)
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos

func _start_drag():
	Globals.dragging = true
	_drag_parent = _current_card.get_parent()
	_drag_index = _current_card.get_index()
	_drag_local_init_pos = _current_card.position
	_drag_global_init_pos = _current_card.global_position
	_current_card.reparent($".")
	_current_card.start_drag()

func _drag(global_pos: Vector2):
	_current_card.global_position = \
		(_drag_global_init_pos + (global_pos - _drag_click_pos)).round()

func _abort_drag():
	Globals.dragging = false
	_current_card.stop_drag()
	_current_card.reparent(_drag_parent, false)
	_drag_parent.move_child(_current_card, _drag_index)
	_current_card.position = _drag_local_init_pos

func _is_in_playground(global_pos: Vector2):
	var local_rect = playground_shape.shape.get_rect()
	var global_rect = playground_shape.get_global_transform() * local_rect
	return global_rect.has_point(global_pos)

func _is_in_reserve(global_pos: Vector2):
	var local_rect = reserve_shape.shape.get_rect()
	var global_rect = reserve_shape.get_global_transform() * local_rect
	return global_rect.has_point(global_pos)

func _stop_drag(global_pos: Vector2):
	var in_reserve: bool
	if _is_in_reserve(global_pos):
		in_reserve = true
	elif _is_in_playground(global_pos):
		in_reserve = false
	else:
		_abort_drag()
		return

	Globals.dragging = false
	_current_card.stop_drag()

	if in_reserve:
		_current_card.is_stacked = true
		_current_card.set_expanded(true)
		_current_card.hide_all_pins()
		for link in links.get_children():
			if link is Link:
				if link.card1 == _current_card:
					link.card2.set_pin_visible(link.pin2, false)
					link.free()
				elif link.card2 == _current_card:
					link.card1.set_pin_visible(link.pin1, false)
					link.free()
		_current_card.reparent(reserve, false)
	else:
		_current_card.is_stacked = false
		_current_card.reparent(cards)
