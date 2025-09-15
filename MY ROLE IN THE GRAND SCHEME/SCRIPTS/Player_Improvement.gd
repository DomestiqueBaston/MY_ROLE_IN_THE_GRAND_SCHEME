extends Node2D

signal done

func _ready():
	$Informations/Quit.pressed.connect(_on_button_pressed)
	$Informations/Quit.mouse_entered.connect(_on_button_mouse_entered)
	$Informations/Quit.mouse_exited.connect(_on_button_mouse_exited)

func _on_button_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	done.emit()

func _on_button_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_button_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
