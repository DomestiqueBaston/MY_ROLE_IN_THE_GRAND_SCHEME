@tool
extends CardStack

## Width of the reserve before unfolding.
@export var folded_width: int = 107
## Maximum width of the reserve when it is unfolded.
@export var unfolded_width: int = 607
## Desired spacing between cards that unfolding aims to obtain.
@export var ideal_card_margin: int = 12

@onready var expansion_panel: Panel = $"../Reserve_Expansion/Reserve_Expansion"

var _is_mouse_inside: bool = false
var _is_folded: bool = true
var _fold_tween: Tween

func _init():
	orientation = HORIZONTAL

func _input(event: InputEvent):
	if Engine.is_editor_hint():
		super(event)
		return

	if (event is not InputEventMouseMotion or
		(_fold_tween and _fold_tween.is_running()) or
		Globals.dragging):
		return

	# if the mouse is outside the bounding box, refold if necessary

	var mouse_inside = contains_point(event.global_position)

	if not mouse_inside and not _is_folded:
		_is_mouse_inside = mouse_inside
		_fold()
		# clear current card
		super(event)
		return

	# if the mouse has just entered the bounding box, maybe unfold

	var card_count = get_child_count()

	if _is_mouse_inside != mouse_inside:
		_is_mouse_inside = mouse_inside
		var ideal_width: int = BaseCard.size.x + ideal_card_margin * (card_count - 1)
		if mouse_inside and _is_folded and ideal_width - size.x >= 50:
			_unfold(mini(ideal_width, unfolded_width))
			return

	super(event)

func _fold():
	_fold_tween = create_tween().set_parallel()
	_fold_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_fold_tween.tween_property(self, "size:x", folded_width, 0.1)
	_fold_tween.tween_property(self, "z_index", 0, 0.1)
	_fold_tween.tween_property(expansion_panel, "size:x", 1, 0.1)
	_fold_tween.tween_property(expansion_panel, "visible", false, 0.0666)
	$"../Reserve_Expansion/Folding".play()
	_is_folded = true

func _unfold(width: int):
	z_index = 1
	expansion_panel.show()
	_fold_tween = create_tween().set_parallel()
	_fold_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_fold_tween.tween_property(self, "size:x", width, 0.1)
	_fold_tween.tween_property(
		expansion_panel, "size:x", width - folded_width + 5, 0.1)
	$"../Reserve_Expansion/Unfolding".play()
	_is_folded = false

func _layout():
	super()

	# this prevents _input() from unfolding the reserve right after a card has
	# been dropped into it; the user has to exit the bounding box first

	if not Engine.is_editor_hint():
		_is_mouse_inside = true
