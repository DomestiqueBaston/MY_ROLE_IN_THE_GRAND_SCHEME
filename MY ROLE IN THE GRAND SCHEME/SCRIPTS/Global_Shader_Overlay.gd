extends CanvasLayer


func _ready() -> void:
	# This causes the overlay to be drawn on top of popup menus.
	set_layer(1025)
	# Make sure the GSO is shown.
	visible = true
