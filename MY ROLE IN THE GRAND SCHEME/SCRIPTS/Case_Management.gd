extends Node2D

signal done

var _open_cases: Array[Case]
var _case_changed: bool

func _ready():
	for button: BaseButton in $Buttons.get_children():
		button.mouse_entered.connect(Globals.on_mouse_entered.bind(button))
		button.mouse_exited.connect(Globals.on_mouse_exited.bind(button))
		button.pressed.connect(_on_button_pressed.bind(button))

func start():
	_open_cases = GameState.get_open_cases()

	for button: BaseButton in [$Buttons/Cancel, $Buttons/Switch]:
		button.button_pressed = false

	for i in 4:
		var button: BaseButton = $Buttons.find_child("0" + str(i+1), false)
		button.disabled = _open_cases.size() <= i
		button.button_pressed = (
			i < _open_cases.size() and
			_open_cases[i] == GameState.get_current_case())

	_enable_disable_switch_button()

func reset():
	_open_cases.clear()

#
# Enables the switch button only if a case other than the current case has been
# selected.
#
func _enable_disable_switch_button():
	var idx = _get_current_index()
	$Buttons/Switch.disabled = \
		idx < 0 or _open_cases[idx] == GameState.get_current_case()

#
# Returns the index of the open case that has been selected (0-3).
#
func _get_current_index() -> int:
	var group = $"Buttons/01".button_group
	var button = group.get_pressed_button()
	return (button.name.to_int() - 1) if button else -1

##
## Returns true if the user selected a new case and then clicked on Switch.
##
func has_case_changed() -> bool:
	return _case_changed

func _on_button_pressed(button: BaseButton):
	if button == $Buttons/Switch:
		Globals.valid_sound.play()
		await Globals.valid_sound.finished
		var case_index = GameState.find_case(_open_cases[_get_current_index()])
		GameState.set_current_case(case_index)
		_case_changed = true
		done.emit()
	elif button == $Buttons/Cancel:
		Globals.cancel_sound.play()
		await Globals.cancel_sound.finished
		_case_changed = false
		done.emit()
	else:
		_enable_disable_switch_button()
		var pitches = [0.75, 1.0, 1.333]
		$Drawer.pitch_scale = pitches.pick_random()
		$Drawer.play()
