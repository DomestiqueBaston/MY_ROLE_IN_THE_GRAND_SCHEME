extends Label

@onready var _card: Card = $"../../../.."

func _get_tooltip(_at_position):
	return _card.tooltip if not _card.is_stacked() else ""
