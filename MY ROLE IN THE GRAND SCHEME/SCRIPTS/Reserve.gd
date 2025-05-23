extends Node2D

@export var size: Vector2 = Vector2(107, 100)
@export var card_size: Vector2 = Vector2(74, 100)
@export var card_margin: int = 3

var _first_card_index: int = 0
var _current_card: int = -1
var _tween: Tween

const _tween_duration: float = 0.1
const _max_displacement: int = 5
const _mid_displacement: int = 2
const _min_displacement: int = 1

func _ready():
	_layout()
	child_order_changed.connect(_layout)
		
func _input(event: InputEvent):
	if event is not InputEventMouseMotion or Globals.dragging or get_child_count() == 0:
		return

	# TODO: if reserve is full, expand while mouse is over it

	var new_card = _current_card
	var local_pos = to_local(event.global_position)
	var bbox = Rect2(Vector2(0, 0), size)
	if bbox.has_point(local_pos):
		var vis_child_count = get_child_count() - _first_card_index
		var pos = vis_child_count * local_pos.x / size.x
		new_card = clampi(_first_card_index + (pos), 0, vis_child_count - 1)
	else:
		new_card = -1

	if _current_card == new_card:
		return

	if _tween:
		_tween.kill()
	if (_current_card < 0 or new_card < 0):
		_tween = create_tween().set_parallel()
	else:
		_tween = null

	if _current_card >= 0:
		Globals.mouse_exited_card.emit(get_child(_current_card))
	_current_card = new_card
	if _current_card >= 0:
		Globals.mouse_entered_card.emit(get_child(_current_card))

	for idx in get_child_count():
		var dist = -1 if _current_card < 0 else absi(idx - _current_card)
		var disp: int = 0
		match dist:
			0:
				disp = _max_displacement
			1:
				disp = _mid_displacement
			2:
				disp = _min_displacement
		if _tween:
			_tween.tween_property(
				get_child(idx), "position:y", -disp, _tween_duration);
		else:
			get_child(idx).position.y = -disp

func _layout():
	_current_card = -1

	var max_card_count = 1 + int((size.x - card_size.x) / card_margin)
	var card_count = get_child_count()
	if card_count > max_card_count:
		_first_card_index = max_card_count - card_count
	else:
		_first_card_index = 0

	var x = 0
	for card_index in card_count:
		var card: Card = get_child(card_index)
		card.is_stacked = true
		if card_index < _first_card_index:
			card.hide()
		else:
			card.position = Vector2(x, 0)
			card.show()
			x += card_margin
		card_index += 1
