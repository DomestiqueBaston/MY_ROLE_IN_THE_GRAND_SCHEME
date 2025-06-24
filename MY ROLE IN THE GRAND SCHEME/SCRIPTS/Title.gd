extends Node2D

## Signal emitted when the user clicks to continue.
signal next

func _input(event: InputEvent):
	if event.is_action_pressed("Left_Click"):
		get_viewport().set_input_as_handled()
		next.emit()

func _on_animation_player_animation_finished(_anim_name):
	$Glow.play("Intro_Loop")
	$Transparency.play("Intro_Loop")
	$Map_Anim.play("Intro_Loop")

##
## Fades out the sound effects and self-destructs when the fade finishes.
##
func fade_out():
	$Sound_Fade_Out.play("Fade_Out")
	await $Sound_Fade_Out.animation_finished
	queue_free()
