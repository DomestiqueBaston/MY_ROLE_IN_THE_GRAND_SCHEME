extends Node2D

var _bbox: Rect2i
var _current_card: int = -1

func _ready():
	for card in get_children():
		var card_bbox = Rect2i(card.position, card.get_size())
		if _bbox:
			_bbox = _bbox.merge(card_bbox)
		else:
			_bbox = card_bbox

func _input(event: InputEvent):
	if event is not InputEventMouseMotion:
		return

	var new_card = _current_card
	if _bbox.has_point(event.position):
		var pos = get_child_count() * (event.position.x - _bbox.position.x) / _bbox.size.x
		new_card = clampi(roundi(pos), 0, get_child_count() - 1)
	else:
		new_card = -1

	if _current_card == new_card:
		return

	if _current_card >= 0:
		get_child(_current_card).set_current(false)
	_current_card = new_card
	if _current_card >= 0:
		get_child(_current_card).set_current(true)

	#for idx in get_child_count():
		#var dist = -1 if _current_card < 0 else absi(idx - _current_card)
		#match dist:
			#0:
				#get_child(idx).position.y = -20
			#1:
				#get_child(idx).position.y = -10
			#2:
				#get_child(idx).position.y = -5
			#_:
				#get_child(idx).position.y = 0
