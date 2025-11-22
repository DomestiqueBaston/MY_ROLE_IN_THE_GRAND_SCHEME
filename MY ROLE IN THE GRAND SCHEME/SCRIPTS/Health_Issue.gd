extends Node2D

signal done

func _ready():
	for button: Button in [
		$Add_Report/Buttons/Ok,
		$Emo_Report/Buttons/Ok,
		$Rest_Report/Buttons/Ok,
		$Health_Report/Buttons/Ok
	]:
		button.mouse_entered.connect(Globals.on_mouse_entered)
		button.mouse_exited.connect(Globals.on_mouse_exited)
		button.pressed.connect(_on_ok_pressed)

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
