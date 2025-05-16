class_name CardStack extends Node2D

## Class to handle interaction with a "stack" of cards, where the cards may be
## very close together.
##
## Usually Card instances handle selection themselves: when the mouse cursor
## enters a card, that card is made current. But with a stack, the CardStack
## controls which of its card children is current, depending on the position of
## the mouse within the stack.
##
## All of a CardStack's children are assumed to be Card instances. And their
## initial positions in Y should be zero, because the CardStack will move them
## up and down.
##
## For now, stacks are always horizontal, but later we may implement vertical
## stacks.

var _bbox: Rect2i
var _current_card: int = -1
var _tween: Tween

const _tween_duration: float = 0.2
const _max_displacement: int = 5
const _mid_displacement: int = 2
const _min_displacement: int = 1

func _ready():
	_update_bbox()

func _update_bbox():
	_bbox = Rect2i()
	for card in get_children():
		var card_bbox = Rect2i(card.position, card.get_size())
		if _bbox:
			_bbox = _bbox.merge(card_bbox)
		else:
			_bbox = card_bbox
	if _bbox:
		_bbox.position.y -= _max_displacement
		_bbox.size.y += _max_displacement

func _input(event: InputEvent):
	if event is not InputEventMouseMotion:
		return

	var new_card = _current_card
	var local_pos = to_local(event.global_position)
	if _bbox.has_point(local_pos):
		var pos = get_child_count() * (local_pos.x - _bbox.position.x) / _bbox.size.x
		new_card = clampi(roundi(pos), 0, get_child_count() - 1)
	else:
		new_card = -1

	if _current_card == new_card:
		return

	var do_tween = (_current_card < 0 or new_card < 0)

	if _current_card >= 0:
		get_child(_current_card).set_current(false)
	_current_card = new_card
	if _current_card >= 0:
		get_child(_current_card).set_current(true)

	if _tween:
		_tween.kill()
	if do_tween:
		_tween = create_tween().set_parallel()
	else:
		_tween = null

	for idx in get_child_count():
		var dist = -1 if _current_card < 0 else absi(idx - _current_card)
		var disp: int = 0
		match dist:
			0:
				disp = - _max_displacement
			1:
				disp = - _mid_displacement
			2:
				disp = - _min_displacement
		if do_tween:
			_tween.tween_property(
				get_child(idx), "position:y", disp, _tween_duration);
		else:
			get_child(idx).position.y = disp
