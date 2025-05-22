extends Control


@onready var buttons = [
	$Cancel,
	$Switch,
	$"03",
	$"04",
	$"01",
	$"02"
]

func _ready():
	for button in buttons:
		button.pressed.connect(play_sound)

func _on_any_button_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished

func _on_switch_pressed():
	if $"01".button_pressed or $"02".button_pressed or $"03".button_pressed or $"04".button_pressed:
		Globals.valid_sound.play()
		await Globals.valid_sound.finished
		$"../../../On_Off".play("Disappearance")
		await $"../../../On_Off".animation_finished
	else:
		$Switch.button_pressed = false

func _on_any_button_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func play_sound():
	$"../Drawer".volume_db = 0.0
	if $Cancel.button_pressed or $Switch.button_pressed:
		$"../Drawer".volume_db = -5.0
	var pitches = [0.75, 1.0, 1.333]
	var pitch = pitches[randi() % pitches.size()]
	$"../Drawer".pitch_scale = pitch
	$"../Drawer".play()
