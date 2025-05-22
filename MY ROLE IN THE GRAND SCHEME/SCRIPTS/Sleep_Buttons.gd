extends Control


@onready var buttons = [
	$Drawer_09,
	$Drawer_08,
	$Drawer_07,
	$Drawer_06,
	$Drawer_05,
	$Drawer_04,
	$Drawer_03,
	$Drawer_02,
	$Drawer_01
]

func _ready():
	for button in buttons:
		button.pressed.connect(play_sound)

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_yes_pressed():
	if $Drawer_09.button_pressed == true or $Drawer_08.button_pressed == true or $Drawer_07.button_pressed == true or $Drawer_06.button_pressed == true or $Drawer_05.button_pressed == true or $Drawer_04.button_pressed == true or $Drawer_03.button_pressed == true or $Drawer_02.button_pressed == true or $Drawer_01.button_pressed == true:
		Globals.valid_sound.play()
		await Globals.valid_sound.finished
		$"../../../On_Off".play("Disappearance")
		await $"../../../On_Off".animation_finished
	else:
		Globals.cancel_sound.play()

func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished

func play_sound():
	var pitches = [0.75, 1.0, 1.25]
	var pitch = pitches[randi() % pitches.size()]
	$"../Drawer".pitch_scale = pitch
	$"../Drawer".play()
