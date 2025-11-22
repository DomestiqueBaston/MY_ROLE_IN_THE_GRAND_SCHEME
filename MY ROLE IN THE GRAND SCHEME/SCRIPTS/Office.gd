extends Node2D

signal done

func _ready():
	$Office/Quit.pressed.connect(_on_quit_pressed)
	$Office/Quit.mouse_entered.connect(Globals.on_mouse_entered)
	$Office/Quit.mouse_exited.connect(Globals.on_mouse_exited)

func _on_quit_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	done.emit()
