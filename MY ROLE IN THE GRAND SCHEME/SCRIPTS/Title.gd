extends Node2D


func _ready():
	$Shader_Overlay.visible = true



func _on_animation_player_animation_finished(_Intro) -> void:
	$Glow.play("Intro_Loop")
	$Transparency.play("Intro_Loop")
