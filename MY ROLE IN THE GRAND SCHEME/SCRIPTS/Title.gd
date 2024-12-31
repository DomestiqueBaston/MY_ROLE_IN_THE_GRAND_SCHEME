extends Node2D


func _ready():
	$Shader_Overlay.visible = true
	
	# This causes the overlay to be drawn on top of popup menus.
	$Shader_Overlay.set_layer(1025)


func _on_animation_player_animation_finished(_Intro) -> void:
	$Glow.play("Intro_Loop")
	$Transparency.play("Intro_Loop")
