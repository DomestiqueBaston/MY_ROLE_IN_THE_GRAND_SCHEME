extends Node2D

signal done

func _ready():
	$Language_Bg/Quit_Button/Quit.pressed.connect(_on_quit_pressed)
	$Language_Bg/Quit_Button/Quit.mouse_entered.connect(_on_mouse_entered)
	$Language_Bg/Quit_Button/Quit.mouse_exited.connect(_on_mouse_exited)

func _on_quit_pressed():
	Globals.valid_sound.play()
	$Quit_Animation.stop()
	await Globals.valid_sound.finished
	done.emit()

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
