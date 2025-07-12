extends Node2D

@export var bounds: SizedNode2D

var _the_card: BaseCard

func attach_to_card(card: BaseCard):
	detach_from_card()
	_the_card = card
	_the_card.moved.connect(_on_card_move)
	_the_card.tree_entered.connect(_on_card_entered_tree)
	_the_card.tree_exited.connect(_on_card_exited_tree)
	visible = not _the_card.is_stacked()

func detach_from_card():
	if _the_card:
		_the_card.moved.disconnect(_on_card_move())
		_the_card.tree_entered.disconnect(_on_card_entered_tree)
		_the_card.tree_exited.disconnect(_on_card_exited_tree)
		_the_card = null

func _on_card_move():
	if not visible:
		return

	var pos = _the_card.global_position

	if not bounds:
		global_position = pos
		rotation = 0
		return

	var bounds_center = bounds.global_position + bounds.size * 0.5
	var card_center = pos + BaseCard.reduced_size * 0.5

	if card_center.x < bounds_center.x:
		if card_center.y < bounds_center.y:
			global_position = pos + Vector2(BaseCard.reduced_size)
			rotation = PI * 0.5
		else:
			global_position = pos + Vector2(BaseCard.reduced_size.x, 0)
			rotation = PI * 0.4
	else:
		if card_center.y < bounds_center.y:
			global_position = pos + Vector2(0, BaseCard.reduced_size.y)
			rotation = PI * -0.5
		else:
			global_position = pos
			rotation = PI * -0.4

func _on_card_entered_tree():
	visible = not _the_card.is_stacked()

func _on_card_exited_tree():
	visible = false
