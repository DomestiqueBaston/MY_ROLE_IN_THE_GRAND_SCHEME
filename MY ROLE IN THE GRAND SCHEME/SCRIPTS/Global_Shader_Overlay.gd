extends CanvasLayer


func _ready() -> void:
	$".".visible = true
	
	# This causes the overlay to be drawn on top of popup menus.
	$".".set_layer(1025)
