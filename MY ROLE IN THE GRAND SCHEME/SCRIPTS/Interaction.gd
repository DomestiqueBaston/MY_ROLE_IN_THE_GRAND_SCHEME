extends Node2D

@onready var interaction_cards: Node2D = $Cards/Interaction
@onready var the_button: BaseButton = $Button/Bring_It_On
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

# overlay highlighting the card pile concerned by drag & drop
var _highlighted_overlay: Sprite2D

# number of cards that the interactoin zone can hold
const kMaxCardCount = 3

# collider shapes used to detect when the mouse is in card areas
@onready var _area_shapes = {
	$Cards/Fallback:	$Colliders/Fallback_Area/Fallback,
	$Cards/Mastery:		$Colliders/Mastery_Area/Mastery,
	$Cards/Evidence:	$Colliders/Evidence_Area/Evidence,
	$Cards/NPCs:		$Colliders/NPC_Area/NPC,
	$Cards/Objects:		$Colliders/Object_Area/Object,
	$Cards/Locations:	$Colliders/Place_Area/Place,
	$Cards/Interaction:	$Colliders/Interaction_Area/Interaction_Collider
}

# overlay to highlight the name of each card pile
@onready var _area_overlays = {
	$Cards/Fallback:	$Interaction_BG/Fallback_Pile,
	$Cards/Mastery:		$Interaction_BG/Mastery_Pile,
	$Cards/Evidence:	$Interaction_BG/Evidence_Pile,
	$Cards/NPCs:		$Interaction_BG/Characters_Pile,
	$Cards/Objects:		$Interaction_BG/Objects_Pile,
	$Cards/Locations:	$Interaction_BG/Locations_Pile
}

# cards that have been dragged to the interaction zone, and which piles they
# came from
var _cards_played: Dictionary

func _ready():
	Globals.mouse_entered_card.connect(_mouse_entered_card)
	Globals.mouse_exited_card.connect(_mouse_exited_card)
	Globals.card_left_click.connect(_click_on_card)
	the_button.disabled = true

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

	if _cards_played.size() < kMaxCardCount:
		var in_interaction_zone = _is_in_collision_shape(
			$Colliders/Interaction_Area/Interaction_Collider, global_pos)
		if $Hover_Interaction_Zone.visible != in_interaction_zone:
			$Hover_Interaction_Zone.visible = in_interaction_zone
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
	# original pile or somewhere else in the interaction area

	if _current_card in _cards_played:
		var old_parent = _cards_played[_current_card]
		if new_parent != interaction_cards and new_parent != old_parent:
			_abort_drag()
			return
		if new_parent == old_parent:
			_cards_played.erase(_current_card)
			_current_card.reparent(new_parent, false)

	# if the card is in a pile, it can only be dropped in the interaction area

	else:
		if new_parent != interaction_cards or _cards_played.size() == kMaxCardCount:
			_abort_drag()
			return
		_cards_played[_current_card] = _current_card.get_parent()
		_current_card.reparent(interaction_cards)

	_stuff_to_do_when_drag_ends(_current_card)
	the_button.disabled = _cards_played.is_empty()

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	drag_drop_line.hide_line()
	if dragged_card:
		dragged_card.stop_drag()
	Globals.dragging = false
	$Hover_Interaction_Zone.hide()
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
