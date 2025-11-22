extends Node2D

signal button_pressed(which: StringName)

var _secret_clicks = 0
var _minions_state = false
var _input_paused = false

func _ready():
	for button: BaseButton in $Drawers.get_children():
		button.pressed.connect(_on_button_pressed.bind(button))
		button.mouse_entered.connect(Globals.on_mouse_entered)
		button.mouse_exited.connect(Globals.on_mouse_exited)

	$Drawers/Continue.disabled = (GameState.player.health == 0)

	Globals.dialog_overlay.pre_dialog.connect(_pause_input_handling)
	Globals.dialog_overlay.post_dialog.connect(_resume_input_handling)

func _on_button_pressed(button: BaseButton):
	var button_name = StringName(button.name)

	if button_name in [&"Secrets", &"Quit"]:
		Globals.cancel_sound.play()
	else:
		Globals.valid_sound.play()

	if button_name == &"Secrets":
		_secret_clicks += 1
		if _secret_clicks % 10 == 0:
			if _minions_state:
				$Minions_Off.play()
			else:
				$Minions_On.play()
			_minions_state = not _minions_state
	else:
		var pitches = [0.75, 1.0, 1.25]
		var pitch = pitches[randi() % pitches.size()]
		$Drawer.pitch_scale = pitch
		$Drawer.play()
		await $Drawer.finished

	button_pressed.emit(button_name)

func _pause_input_handling():
	_input_paused = true
	for button: BaseButton in $Drawers.get_children():
		button.disabled = true

func _resume_input_handling():
	_input_paused = false
	for button: BaseButton in $Drawers.get_children():
		if button == $Drawers/Continue:
			button.disabled = (GameState.player.health == 0)
		else:
			button.disabled = false
		button.button_pressed = false
