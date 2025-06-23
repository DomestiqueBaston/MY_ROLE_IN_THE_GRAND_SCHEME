extends Node2D

## Signal emitted when the user clicks on the Next button.
signal next

func _on_animation_player_animation_finished(_anim_name):
	$Glow.play("Intro_Loop")
	$Transparency.play("Intro_Loop")
	$Map_Anim.play("Intro_Loop")

func _on_next_pressed():
	next.emit()
