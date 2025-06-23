extends Node2D

var _option_menu = preload("res://SCENES/Option_Menu.tscn")

func _on_animation_player_animation_finished(_anim_name):
	$Glow.play("Intro_Loop")
	$Transparency.play("Intro_Loop")
	$Map_Anim.play("Intro_Loop")

func _on_next_pressed():
	$Transition.start_transition_to(_option_menu)
