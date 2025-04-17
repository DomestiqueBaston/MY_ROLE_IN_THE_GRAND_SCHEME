extends Button



func _on_yes_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished


func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished


func _on_any_button_entered():
	if not Globals.leave_sound.playing:
		Globals.hover_sound.play()


func _on_any_button_exited():
	if not Globals.hover_sound.playing:
		Globals.leave_sound.play()
