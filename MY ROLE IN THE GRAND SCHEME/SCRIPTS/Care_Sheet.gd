extends Node2D

signal done

var _confirmed: bool

func _ready():
	$Note/Yes.pressed.connect(_on_yes_pressed)
	$Note/Yes.mouse_entered.connect(_on_any_button_entered)
	$Note/Yes.mouse_exited.connect(_on_any_button_exited)

	$Note/No.pressed.connect(_on_no_pressed)
	$Note/No.mouse_entered.connect(_on_any_button_entered)
	$Note/No.mouse_exited.connect(_on_any_button_exited)

func get_confirmed() -> bool:
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

func _on_any_button_entered():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.hover_sound.play()

func _on_any_button_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
