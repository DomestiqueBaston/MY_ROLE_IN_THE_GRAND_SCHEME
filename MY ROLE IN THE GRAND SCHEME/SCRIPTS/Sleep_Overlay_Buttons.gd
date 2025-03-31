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
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()

func _on_yes_pressed():
	if $Drawer_09.button_pressed == true or $Drawer_08.button_pressed == true or $Drawer_07.button_pressed == true or $Drawer_06.button_pressed == true or $Drawer_05.button_pressed == true or $Drawer_04.button_pressed == true or $Drawer_03.button_pressed == true or $Drawer_02.button_pressed == true or $Drawer_01.button_pressed == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		await $"../../Shared_Interface_Sounds/Valid".finished
		$"../../On_Off".play("Disappearance")
		await $"../../On_Off".animation_finished
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()

func _on_no_pressed():
	$"../../Shared_Interface_Sounds/Cancel".play()
	await $"../../Shared_Interface_Sounds/Cancel".finished
	$"../../On_Off".play("Disappearance")
	await $"../../On_Off".animation_finished

func play_sound():
	var pitches = [0.75, 1.0, 1.25]
	var pitch = pitches[randi() % pitches.size()]
	$"../../Drawer".pitch_scale = pitch
	$"../../Drawer".play()
