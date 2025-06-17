class_name CardStack extends Node2D

## A CardStack is a stack of cards where each card is offset by a few pixels
## from its neighbors, and only a single card is "current". When the current
## card changes, Globals.mouse_exited_card() and Globals.mouse_entered_card()
## signals are emitted.
##
## If the stack's orientation is HORIZONTAL, cards are offset from one another
## in X, otherwise they are offset in Y.
##
## It is assumed that a CardStack's children are all instances of Card. When
## children are added or removed, the cards are rearranged, depending on the
## number of cards and the size of the CardStack: see _layout().

enum {
	HORIZONTAL,
	VERTICAL
}

## Orientation of the stack.
@export_enum("Horizontal", "Vertical") var orientation: int = HORIZONTAL

## Size of the stack area (regardless of how many cards it contains).
@export var size: Vector2 = Vector2(107, 100):
	set(value):
		size = value
		_layout()

## Size of a single card.
@export var card_size: Vector2i = Vector2i(74, 100)

## Minimum allowed space between cards (first cards are hidden if necessary).
@export var min_card_margin: int = 3

var _max_card_count: int
var _current_card: int = -1
var _tween: Tween

const _tween_duration: float = 0.1
const _max_displacement: int = 5
const _mid_displacement: int = 2
const _min_displacement: int = 1

##
## Returns true if the given point is inside the CardStack's bounding box.
##
func contains_point(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	var bbox = Rect2(Vector2(0, 0), size)
	return bbox.has_point(local_pos)

func _ready():
	_layout()
	child_order_changed.connect(_layout)

##
## The CardStack's _input() method is responsible for determining which card, if
## any, is under the mouse, and for emitting signals when the mouse leaves the
## current card or enters a new one. It also displaces the cards a little bit
## (in Y for a horizontal stack, in X for a vertical stack) as the mouse moves
## over them.
##
func _input(event: InputEvent):
	if (event is not InputEventMouseMotion or Globals.dragging
		or get_child_count() == 0):
		return

	var mouse_inside = contains_point(event.global_position)
	var card_count = get_child_count()
	var new_card = -1

	if mouse_inside:
		var vis_card_count = mini(card_count, _max_card_count)
		var first_card_index = card_count - vis_card_count
		var local_pos = to_local(event.global_position)
		var component = 0 if orientation == HORIZONTAL else 1
		var card_index = first_card_index + \
			int(vis_card_count * local_pos[component] / size[component])
		if card_index < get_child_count():
			new_card = card_index

	if _current_card == new_card:
		return

	if _tween:
		_tween.kill()
	if (_current_card < 0 or new_card < 0):
		_tween = create_tween().set_parallel()
	else:
		_tween = null

	var displace_component
	var displace_prop
	var displace_sign

	if orientation == HORIZONTAL:
		displace_component = 1
		displace_prop = "position:y"
		displace_sign = -1
	else:
		displace_component = 0
		displace_prop = "position:x"
		displace_sign = 1

	if _current_card >= 0:
		Globals.mouse_exited_card.emit(get_child(_current_card))
	_current_card = new_card
	if _current_card >= 0:
		Globals.mouse_entered_card.emit(get_child(_current_card))

	for idx in card_count:
		var dist = -1 if _current_card < 0 else absi(idx - _current_card)
		var disp: int = 0
		match dist:
			0:
				disp = _max_displacement * displace_sign
			1:
				disp = _mid_displacement * displace_sign
			2:
				disp = _min_displacement * displace_sign
		if _tween:
			_tween.tween_property(
				get_child(idx), displace_prop, disp, _tween_duration);
		else:
			get_child(idx).position[displace_component] = disp

##
## Arranges the cards within the CardStack. If there is not enough room to show
## all of them, the first cards (i.e. leftmost or topmost) are hidden. This is
## called whenever a card is added to or removed from the stack.
##
func _layout():
	var component = 0 if orientation == HORIZONTAL else 1
	var avail_space = size[component] - card_size[component]

	_current_card = -1
	_max_card_count = 1 + int(avail_space / min_card_margin)

	var card_count = get_child_count()
	var vis_card_count = mini(card_count, _max_card_count)
	var first_card_index = card_count - vis_card_count

	var margin = min_card_margin
	if vis_card_count > 1:
		margin = int(avail_space / (vis_card_count - 1))

	var x = 0
	for card_index in card_count:
		var card: Card = get_child(card_index)
		card.is_stacked = true
		if card_index < first_card_index:
			card.hide()
		else:
			card.position = Vector2(x, 0) if orientation == HORIZONTAL else Vector2(0, x)
			card.show()
			x += margin
		card_index += 1
