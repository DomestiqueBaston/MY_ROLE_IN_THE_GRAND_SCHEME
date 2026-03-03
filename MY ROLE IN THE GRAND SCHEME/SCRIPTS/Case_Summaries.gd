extends Control

## Signal emitted when the player presses the quit button.
signal done

func _ready():
	$Quit.pressed.connect(_on_pressed)
	$Quit.mouse_entered.connect(Globals.on_mouse_entered)
	$Quit.mouse_exited.connect(Globals.on_mouse_exited)

func _on_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
