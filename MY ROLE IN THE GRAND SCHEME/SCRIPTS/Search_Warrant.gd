extends Control

signal done

var _confirmed: bool

func _ready():
	var no_button = find_child("No", false)
	if no_button:
		no_button.pressed.connect(_on_no_pressed)
		no_button.mouse_entered.connect(Globals.on_mouse_entered)
		no_button.mouse_exited.connect(Globals.on_mouse_exited)

	$Yes.pressed.connect(_on_yes_pressed)
	$Yes.mouse_entered.connect(Globals.on_mouse_entered)
	$Yes.mouse_exited.connect(Globals.on_mouse_exited)

func get_confirmed():
	return _confirmed

func _on_yes_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	_confirmed = true
	done.emit()

func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	_confirmed = false
	done.emit()
