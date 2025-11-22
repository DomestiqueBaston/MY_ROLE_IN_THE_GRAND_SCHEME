extends Control

signal done

func _ready():
	$Quit.mouse_entered.connect(Globals.on_mouse_entered)
	$Quit.mouse_exited.connect(Globals.on_mouse_exited)
	$Quit.pressed.connect(_on_quit_pressed)

func _on_quit_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
