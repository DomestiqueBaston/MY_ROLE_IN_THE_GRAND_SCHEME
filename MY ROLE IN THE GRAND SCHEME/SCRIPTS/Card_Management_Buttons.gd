extends Control

signal ok
signal cancel

func _ready():
	$Ok.mouse_entered.connect(Globals.on_mouse_entered)
	$Ok.mouse_exited.connect(Globals.on_mouse_exited)
	$Ok.pressed.connect(_on_ok_pressed)

	$Exit.mouse_entered.connect(Globals.on_mouse_entered)
	$Exit.mouse_exited.connect(Globals.on_mouse_exited)
	$Exit.pressed.connect(_on_cancel_pressed)

func _on_cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	cancel.emit()

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	ok.emit()
