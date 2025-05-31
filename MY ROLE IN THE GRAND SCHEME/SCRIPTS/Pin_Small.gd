@tool
class_name Pin_Small extends Node2D

## Signal emitted when the pin's position may have changed.
signal moved

func _ready():
	set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		moved.emit()

func get_collider() -> Area2D:
	return $Collider

func get_card() -> Card:
	var node = get_parent()
	while node:
		if node is Card:
			return node
		node = node.get_parent()
	return null
