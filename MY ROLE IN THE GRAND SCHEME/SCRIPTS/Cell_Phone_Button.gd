extends Control


func _on_any_button_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_any_button_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_switch_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished
