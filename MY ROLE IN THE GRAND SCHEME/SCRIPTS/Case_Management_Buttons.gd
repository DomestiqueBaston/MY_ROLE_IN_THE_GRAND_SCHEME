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

func _on_any_button_pressed():
	play_sound()

func _on_any_button_mouse_entered():
	$"../../Hover".play()

func _on_cancel_pressed():
	$"../../Cancel".play()
	#await $"../../Cancel".finished

func _on_switch_pressed():
	$"../../Valid".play()

func _on_any_button_mouse_exited():
	pass
	#$"../../Leave".play()

func play_sound():
	$"../../Drawer".volume_db = 0.0
	if $Cancel.button_pressed == true or $Switch.button_pressed == true:
		$"../../Drawer".volume_db = -7.5
	var pitches = [0.666, 1.0, 1.5]
	var pitch = pitches[randi() % pitches.size()]
	$"../../Drawer".pitch_scale = pitch
	$"../../Drawer".play()
