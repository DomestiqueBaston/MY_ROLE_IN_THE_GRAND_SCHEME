extends Control

@onready var the_button = $Bring_It_On

func _on_bring_it_on_pressed():
	Globals.valid_sound.play()

func _on_bring_it_on_mouse_entered():
	if not (the_button.disabled or Globals.leave_sound.playing):
		Globals.hover_sound.play()

func _on_bring_it_on_mouse_exited():
	if not (the_button.disabled or Globals.hover_sound.playing):
		Globals.leave_sound.play()
