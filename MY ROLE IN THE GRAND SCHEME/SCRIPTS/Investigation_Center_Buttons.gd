extends Button


func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()


func _on_cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished


func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
