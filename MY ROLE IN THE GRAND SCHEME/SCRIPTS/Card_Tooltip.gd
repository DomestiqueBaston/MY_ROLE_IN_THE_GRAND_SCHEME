extends Label

@onready var _card: BaseCard = $"../../../.."

func _get_tooltip(_at_position):
	return _card.tooltip if not _card.is_stacked() else ""
