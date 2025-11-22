extends Node2D

## Signal emitted when the user has made a choice or cancelled. Call
## get_hours_chosen() to find out what he selected.
signal done

# drawers and the corresponding number of hours to sleep
@onready var _buttons = {
	$Drawer_Names/Drawer_09: 4,
	$Drawer_Names/Drawer_08: 5,
	$Drawer_Names/Drawer_07: 6,
	$Drawer_Names/Drawer_06: 7,
	$Drawer_Names/Drawer_05: 8,
	$Drawer_Names/Drawer_04: 9,
	$Drawer_Names/Drawer_03: 10,
	$Drawer_Names/Drawer_02: 11,
	$Drawer_Names/Drawer_01: 12
}

var _button_chosen: BaseButton

##
## Call this to reset the dialog to its initial state (no drawer selected).
##
func reset():
	if _button_chosen:
		_button_chosen.set_pressed_no_signal(false)
		_button_chosen = null

##
## Returns the number of hours selected by the user, or 0 if he cancelled.
##
func get_hours_chosen() -> int:
	if _button_chosen:
		return _buttons[_button_chosen]
	else:
		return 0

func _ready():
	for button in _buttons:
		button.pressed.connect(_on_drawer_pressed.bind(button))
		button.mouse_entered.connect(Globals.on_mouse_entered)
		button.mouse_exited.connect(Globals.on_mouse_exited)

	$Yes_No/No.pressed.connect(_on_no_pressed)
	$Yes_No/No.mouse_entered.connect(Globals.on_mouse_entered)
	$Yes_No/No.mouse_exited.connect(Globals.on_mouse_exited)

func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	reset()
	done.emit()

func _on_drawer_pressed(button: BaseButton):
	var pitches = [0.75, 1.0, 1.25]
	var pitch = pitches[randi() % pitches.size()]
	$Drawer.pitch_scale = pitch
	$Drawer.play()
	await $Drawer.finished
	_button_chosen = button
	done.emit()
