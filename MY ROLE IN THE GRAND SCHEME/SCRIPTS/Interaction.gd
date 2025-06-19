extends Node2D

## Collider shapes used to detect when the mouse is in a card area. Keys and
## values in the Dictionary are all NodePaths: each key is a Node2D containing
## cards, and its value is the corresponding CollisionShape2D.
@export var card_area_shapes: Dictionary

## Overlays used to highlight each care area. Keys and values in the Dictionary
## are all NodePaths: each key is a Node2D containing cards, and its value is
## the corresponding overlay to be shown or hidden.
@export var card_area_overlays: Dictionary

## The Node2D containing cards dropped in the interaction zone.
@export var interaction_cards: Node2D

## The maximum number of cards that the interaction zone can hold.
@export var max_card_count: int = 3

## The minimum number of cards in the interaction zone required before the
## button is enabled.
@export var min_card_count: int = 1

## The button that can be pressed when cards are ready.
@export var the_button: BaseButton

## The line used to illustrate drag & drop operations (an instance of
## Drag_Drop_Line.tscn).
@export var drag_drop_line: Node2D

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

# overlay highlighting the card pile concerned by drag & drop
var _highlighted_overlay: CanvasItem

# collider shapes used to detect when the mouse is in card areas
var _area_shapes = {}

# overlay to highlight the name of each card pile
var _area_overlays = {}

# cards that have been dragged to the interaction zone, and which piles they
# came from
var _cards_played: Dictionary

func _ready():
	for area in card_area_shapes:
		_area_shapes[get_node(area)] = get_node(card_area_shapes[area])
	for area in card_area_overlays:
		_area_overlays[get_node(area)] = get_node(card_area_overlays[area])
	Globals.mouse_entered_card.connect(_mouse_entered_card)
	Globals.mouse_exited_card.connect(_mouse_exited_card)
	Globals.card_left_click.connect(_click_on_card)
	the_button.disabled = (min_card_count > 0)

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

	# highlight the name of the pile the card belongs to

	var pile = _cards_played.get(_current_card, _current_card.get_parent())
	_highlighted_overlay = _area_overlays[pile]
	_highlighted_overlay.show()

	return true

func _drag(global_pos: Vector2):

	# move the card and the endpoint of the drag & drop line

	_current_card.global_position = \
		(_drag_global_init_pos + (global_pos - _drag_click_pos)).round()
	drag_drop_line.point2 = global_pos

	# highlight the interaction zone when the mouse enters it, with a sound
	# effect

	if _cards_played.size() < max_card_count:
		var shape = _area_shapes[interaction_cards]
		var overlay = _area_overlays[interaction_cards]
		var in_interaction_zone = _is_in_collision_shape(shape, global_pos)
		if overlay.visible != in_interaction_zone:
			overlay.visible = in_interaction_zone
			if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
				if in_interaction_zone:
					Globals.hover_sound.play()
				else:
					Globals.leave_sound.play()

func _abort_drag():
	drag_drop_line.hide_line()
	var card = _current_card
	var tween = create_tween()
	tween.tween_property(card, "position", _drag_local_init_pos, 0.15)
	await tween.finished
	_stuff_to_do_when_drag_ends(card)

func _stop_drag(global_pos: Vector2):

	# what card area did the user drop the card over?

	var new_parent = _get_card_area_at(global_pos)
	if not new_parent:
		_abort_drag()
		return

	# if the card is in the interaction area, it can only be dropped back on its
	# original pile

	if _current_card in _cards_played:
		if new_parent != _cards_played[_current_card]:
			_abort_drag()
			return
		_cards_played.erase(_current_card)
		_current_card.reparent(new_parent, false)

	# if the card is in a pile, it can only be dropped in the interaction area,
	# and only until it is full

	else:
		if new_parent != interaction_cards or _cards_played.size() == max_card_count:
			_abort_drag()
			return
		_cards_played[_current_card] = _current_card.get_parent()
		_current_card.reparent(interaction_cards)

	_stuff_to_do_when_drag_ends(_current_card)
	the_button.disabled = _cards_played.size() < min_card_count
	_layout_played_cards()

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	drag_drop_line.hide_line()
	if dragged_card:
		dragged_card.stop_drag()
	Globals.dragging = false
	_area_overlays[interaction_cards].hide()
	_highlighted_overlay.hide()

func _get_card_area_at(global_pos: Vector2) -> Node2D:
	for area in _area_shapes:
		if _is_in_collision_shape(_area_shapes[area], global_pos):
			return area
	return null

func _is_in_collision_shape(shape: CollisionShape2D, global_pos: Vector2):
	var local_rect = shape.shape.get_rect()
	var local_pos = shape.to_local(global_pos)
	return local_rect.has_point(local_pos)

func _layout_played_cards():
	var card_count = _cards_played.size()
	if card_count == 0:
		return

	const margin = 2
	var tween = create_tween().set_parallel()
	var global_center = _area_shapes[interaction_cards].global_position
	var local_center = interaction_cards.to_local(global_center)
	var pos

	if card_count & 1:
		pos = Vector2(local_center.x - Card.size.x * 0.5, 0)
	else:
		pos = Vector2(local_center.x + margin * 0.5, 0)

	if card_count > 1:
		@warning_ignore("integer_division")
		pos.x -= (card_count / 2) * (Card.size.x + margin)

	for card: Card in _cards_played:
		if card.position != pos:
			tween.tween_property(card, "position", pos, 0.1)
		pos.x += Card.size.x + margin
