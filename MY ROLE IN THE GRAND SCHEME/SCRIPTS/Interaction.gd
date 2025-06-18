extends Node2D

@onready var drag_drop_line: Node2D = $Drag_Drop_Line

# highlighted card
var _current_card: Card

# has a card been clicked on, or is it being dragged?
enum DragState {
	NONE,		# nothing is going on
	CLICKED,	# a card has been clicked but is not being dragged yet
	DRAGGING	# a card is being dragged
}
var _drag_state: DragState = DragState.NONE

# card position in local coordinates when dragging began
var _drag_local_init_pos: Vector2

# card position in global coordinates when dragging began
var _drag_global_init_pos: Vector2

# where the user clicked, in global coordinates, to initiate dragging
var _drag_click_pos: Vector2

func _ready():
	Globals.mouse_entered_card.connect(_mouse_entered_card)
	Globals.mouse_exited_card.connect(_mouse_exited_card)
	Globals.card_left_click.connect(_click_on_card)

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
			if _start_drag():
				Globals.dragging = true
				_drag_state = DragState.DRAGGING
			else:
				_drag_state = DragState.NONE
		elif event is InputEventMouseButton and not event.pressed:
			_drag_state = DragState.NONE

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

func _start_drag() -> bool:
	_drag_local_init_pos = _current_card.position
	_drag_global_init_pos = _current_card.global_position
	_current_card.start_drag()

	# turn on the drag & drop line that connects the initial and current
	# mouse positions

	drag_drop_line.point1 = _drag_click_pos
	drag_drop_line.point2 = _drag_click_pos
	drag_drop_line.show_line()

	return true

func _drag(global_pos: Vector2):
	_current_card.global_position = \
		(_drag_global_init_pos + (global_pos - _drag_click_pos)).round()
	drag_drop_line.point2 = global_pos

func _abort_drag():
	drag_drop_line.hide_line()
	var card = _current_card
	var tween = create_tween()
	tween.tween_property(card, "position", _drag_local_init_pos, 0.15)
	await tween.finished
	_stuff_to_do_when_drag_ends(card)

func _stop_drag(_global_pos: Vector2):
	# TODO
	_abort_drag()

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	if dragged_card:
		dragged_card.stop_drag()
	Globals.dragging = false
