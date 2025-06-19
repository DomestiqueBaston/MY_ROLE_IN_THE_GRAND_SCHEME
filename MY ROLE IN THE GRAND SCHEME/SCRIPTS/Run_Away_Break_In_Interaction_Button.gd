extends Control

@onready var the_button = $Bring_It_On
@onready var on_off = $"../../../On_Off"

func _on_bring_it_on_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	on_off.play("Disappearance")
	await on_off.animation_finished

func _on_bring_it_on_mouse_entered():
	if not (the_button.disabled or Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.hover_sound.play()

func _on_bring_it_on_mouse_exited():
	if not (the_button.disabled or Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
