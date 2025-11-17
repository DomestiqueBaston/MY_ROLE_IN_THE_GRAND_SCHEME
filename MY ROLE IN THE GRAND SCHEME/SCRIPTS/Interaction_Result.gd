extends Node2D

signal done

func _ready():
	for button: Button in [$Dialogue/Quit, $Combat/Quit, $Investigation/Quit]:
		button.mouse_entered.connect(_on_mouse_entered)
		button.mouse_exited.connect(_on_mouse_exited)
		button.pressed.connect(_on_quit_pressed)

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_quit_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
