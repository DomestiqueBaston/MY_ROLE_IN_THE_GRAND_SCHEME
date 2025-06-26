extends Node2D

signal done

func _ready():
	$Texts/Ferdi.done.connect(_on_ferdi_done)
	$Button/Ok.pressed.connect(_on_ok_pressed)
	$Button/Ok.mouse_entered.connect(_on_ok_mouse_entered)
	$Button/Ok.mouse_exited.connect(_on_ok_mouse_exited)

func _on_ferdi_done():
	$Button.show()

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()

func _on_ok_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_ok_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
