extends Node2D


func _ready() -> void:
	$Shader_Overlay.visible = true
	
	# This causes the overlay to be drawn on top of popup menus.
	$Shader_Overlay.set_layer(1025)
