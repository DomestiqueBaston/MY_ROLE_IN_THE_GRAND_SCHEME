extends Node2D

signal done

func _ready():
	$Language_Bg/Quit_Button/Quit.pressed.connect(_on_quit_pressed)
	$Language_Bg/Quit_Button/Quit.mouse_entered.connect(Globals.on_mouse_entered)
	$Language_Bg/Quit_Button/Quit.mouse_exited.connect(Globals.on_mouse_exited)

func _on_quit_pressed():
	Globals.valid_sound.play()
	$Quit_Animation.stop()
	await Globals.valid_sound.finished
	done.emit()
