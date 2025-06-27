extends Control


# Un truc est chiant : il faudrait que le slider ne soit sélectionné pour le déplacer
# que lorsque l'on clique sur le grabber, pas dans le grabber area (ce qui est le cas actuellement
# même si c'est pas hyper grave).

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_cancel_pressed():
	Globals.cancel_sound.play()

func _on_ok_pressed():
	Globals.valid_sound.play()

func _on_reset_pressed():
	Globals.cancel_sound.play()

func _on_any_blue_button_pressed():
	Globals.valid_sound.play()

func _on_VS_MC_pressed():
	Globals.valid_sound.play()
