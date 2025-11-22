extends Node2D

signal done

func _ready():
	$Button.hide()
	$Texts/Ferdi.done.connect(_on_ferdi_done)
	$Button/Ok.pressed.connect(_on_ok_pressed)
	$Button/Ok.mouse_entered.connect(Globals.on_mouse_entered)
	$Button/Ok.mouse_exited.connect(Globals.on_mouse_exited)

func _on_ferdi_done():
	$Button.show()

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
