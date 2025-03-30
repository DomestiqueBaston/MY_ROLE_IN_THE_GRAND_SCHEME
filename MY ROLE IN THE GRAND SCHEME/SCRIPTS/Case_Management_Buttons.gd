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
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()

func _on_cancel_pressed():
	$"../../Shared_Interface_Sounds/Cancel".play()
	await $"../../Shared_Interface_Sounds/Cancel".finished
	$"../../On_Off".play("Disappearance")
	await $"../../On_Off".animation_finished

func _on_switch_pressed():
	# Ca ne marche pas, il y a un truc que je n'ai pas compris...
	if $"01".button_pressed == true or $"02".button_pressed == true or $"03".button_pressed == true or $"04".button_pressed == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		await $"../../Shared_Interface_Sounds/Valid".finished
		$"../../On_Off".play("Disappearance")
		await $"../../On_Off".animation_finished
	else:
		$Switch.button_pressed = false

func _on_any_button_mouse_exited():
	if $"../../Shared_Interface_Sounds/Hover".playing == true or $"../../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()

func play_sound():
	$"../../Drawer".volume_db = 0.0
	if $Cancel.button_pressed == true or $Switch.button_pressed == true:
		$"../../Drawer".volume_db = -7.5
	var pitches = [0.666, 1.0, 1.5]
	var pitch = pitches[randi() % pitches.size()]
	$"../../Drawer".pitch_scale = pitch
	$"../../Drawer".play()
