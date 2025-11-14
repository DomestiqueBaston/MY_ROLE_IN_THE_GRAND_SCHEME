extends Control

signal ok
signal cancel

func _ready():
	$Ok.mouse_entered.connect(_on_mouse_entered)
	$Ok.mouse_exited.connect(_on_mouse_exited)
	$Ok.pressed.connect(_on_ok_pressed)

	$Exit.mouse_entered.connect(_on_mouse_entered)
	$Exit.mouse_exited.connect(_on_mouse_exited)
	$Exit.pressed.connect(_on_cancel_pressed)

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	cancel.emit()

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	ok.emit()
