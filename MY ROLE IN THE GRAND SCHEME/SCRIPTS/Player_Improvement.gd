extends Node2D

signal done

func _ready():
	$Informations/Quit.pressed.connect(_on_button_pressed)
	$Informations/Quit.mouse_entered.connect(Globals.on_mouse_entered)
	$Informations/Quit.mouse_exited.connect(Globals.on_mouse_exited)

func _on_button_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	done.emit()
