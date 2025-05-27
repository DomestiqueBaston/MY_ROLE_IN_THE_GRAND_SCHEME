extends Node2D

@export var size: Vector2 = Vector2(107, 100):
	set(value):
		size = value
		_layout()
@export var card_size: Vector2 = Vector2(74, 100)
@export var min_card_margin: int = 3
@export var unfolding_card_count: int = 6

@onready var animation: AnimationPlayer = $"../Reserve_Expansion/Reserve_Animation"

var _max_card_count: int
var _current_card: int = -1
var _tween: Tween

var _is_mouse_inside: bool = false
var _is_folded: bool = true
var _wait_before_folding: bool = false
var _wait_before_unfolding: bool = false

const _tween_duration: float = 0.1
const _max_displacement: int = 5
const _mid_displacement: int = 2
const _min_displacement: int = 1

func _ready():
	_layout()
	child_order_changed.connect(_layout)
		
func _input(event: InputEvent):
	if event is not InputEventMouseMotion or animation.is_playing():
		return

	# is the mouse inside or outside the bounding box?

	var local_pos = to_local(event.global_position)
	var bbox = Rect2(Vector2(0, 0), size)
	var mouse_inside = bbox.has_point(local_pos)

	# if it outside and we have been waiting for dragging to finish before
	# refolding, do it now

	if _wait_before_folding and not mouse_inside and not Globals.dragging:
		_wait_before_folding = false
		if not _is_folded:
			_fold()
			return

	var card_count = get_child_count()

	# if the mouse has entered or exited the bounding box, maybe unfold or
	# refold the reserve now

	if _is_mouse_inside != mouse_inside:
		_is_mouse_inside = mouse_inside
		if Globals.dragging:
			if not mouse_inside:
				_wait_before_folding = true
			return
		if _wait_before_unfolding and not mouse_inside:
			_wait_before_unfolding = false
		if mouse_inside and _is_folded and card_count > unfolding_card_count:
			_unfold()
			return
		if not mouse_inside and not _is_folded:
			_fold()
			return

	# otherwise, if no card is being dragged, see which card is now under the
	# mouse

	if Globals.dragging or get_child_count() == 0:
		return

	var new_card = -1

	if mouse_inside:
		var vis_card_count = mini(card_count, _max_card_count)
		var first_card_index = card_count - vis_card_count
		var card_index = first_card_index + int(vis_card_count * local_pos.x / size.x)
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

func _fold():
	animation.play("Folding")
	await animation.animation_finished
	z_index = 0
	_is_folded = true

func _unfold():
	z_index = 1
	animation.play("Unfolding")
	await animation.animation_finished
	_is_folded = false

func _layout():
	_current_card = -1
	_max_card_count = 1 + int((size.x - card_size.x) / min_card_margin)

	var card_count = get_child_count()
	var vis_card_count = mini(card_count, _max_card_count)
	var first_card_index = card_count - vis_card_count

	var margin = min_card_margin
	if vis_card_count > 1:
		margin = int((size.x - card_size.x) / (vis_card_count - 1))

	var x = 0
	for card_index in card_count:
		var card: Card = get_child(card_index)
		card.is_stacked = true
		if card_index < first_card_index:
			card.hide()
		else:
			card.position = Vector2(x, 0)
			card.show()
			x += margin
		card_index += 1

	if _is_mouse_inside:
		_wait_before_unfolding = true
