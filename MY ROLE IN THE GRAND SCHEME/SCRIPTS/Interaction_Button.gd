extends Control



func _on_bring_it_on_pressed():
	Globals.valid_sound.play()

func _on_bring_it_on_mouse_entered():
	if not Globals.leave_sound.playing:
		Globals.hover_sound.play()

func _on_bring_it_on_mouse_exited():
	if not Globals.hover_sound.playing:
		Globals.leave_sound.play()
