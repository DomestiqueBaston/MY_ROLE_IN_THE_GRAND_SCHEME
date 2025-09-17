extends Node2D

signal done

func _ready():
	$Interface/Quit.pressed.connect(_on_button_pressed)
	$Interface/Quit.mouse_entered.connect(_on_mouse_entered)
	$Interface/Quit.mouse_exited.connect(_on_mouse_exited)

func start():
	$Intercom.play()
	await get_tree().create_timer(0.4).timeout
	$Interface/Screens.show()

func stop():
	$Intercom.stop()
	$Interface/Screens.hide()

func _on_button_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
