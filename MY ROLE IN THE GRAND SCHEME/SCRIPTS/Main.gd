extends Node2D

@onready var popup: PopupMenu = $Mask_Card_Playground/Popup/Main_Menu

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
			_drag(event)
		elif event is InputEventMouseButton and not event.pressed:
			_stop_drag()
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
		if node.find_parent("TMP_2"):
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

func _click_on_card(_global_pos: Vector2, card: Card):
	_mouse_entered_card(card)
	_drag_state = DragState.CLICKED

func _start_drag():
	Globals.dragging = true
	_drag_parent = _current_card.get_parent()
	_drag_index = _current_card.get_index()
	_drag_local_init_pos = _current_card.position
	_current_card.reparent($".")
	_current_card.start_drag()

func _drag(event: InputEventMouseMotion):
	_current_card.global_position += event.relative

func _abort_drag():
	Globals.dragging = false
	_current_card.reparent(_drag_parent, false)
	_drag_parent.move_child(_current_card, _drag_index)
	_current_card.position = _drag_local_init_pos
	_current_card.stop_drag()

func _stop_drag():
	Globals.dragging = false
	# TODO: TMP_1/Main_Playmat or TMP_2/Reserve_Cards
	_current_card.reparent(_drag_parent)
	_current_card.stop_drag()
