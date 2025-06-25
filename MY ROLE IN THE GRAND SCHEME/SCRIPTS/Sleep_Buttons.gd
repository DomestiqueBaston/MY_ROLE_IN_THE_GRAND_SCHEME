extends Control

## Signal emitted when the user has clicked on Yes or No. Call
## get_hours_chosen() to find out what he selected.
signal done

# drawers and the corresponding number of hours to sleep
@onready var _buttons = {
	$Drawer_09: 4,
	$Drawer_08: 5,
	$Drawer_07: 6,
	$Drawer_06: 7,
	$Drawer_05: 8,
	$Drawer_04: 9,
	$Drawer_03: 10,
	$Drawer_02: 11,
	$Drawer_01: 12
}

var _button_chosen: BaseButton

##
## Call this to reset the dialog to its initial state (no drawer selected, Yes
## button disabled).
##
func reset():
	$"../Yes_No/Yes".disabled = true
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

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_yes_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished
	done.emit()

func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished
	reset()
	done.emit()

func _on_drawer_pressed(button: BaseButton):
	var pitches = [0.75, 1.0, 1.25]
	var pitch = pitches[randi() % pitches.size()]
	$"../Drawer".pitch_scale = pitch
	$"../Drawer".play()
	$"../Yes_No/Yes".disabled = false
	_button_chosen = button
