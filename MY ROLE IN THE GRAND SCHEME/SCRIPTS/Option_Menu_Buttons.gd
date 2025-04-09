extends Control

@onready var buttons = [
	$"Secrets", # Il y aura un truc à activer/désactiver dans ce tiroir: des sbires avec +3HEA/HEAnom !
	$"Credits",
	$"Language",
	$"Continue",
	$"Quit",
	$"Settings",
	$"New_Game",
	$"LSD",
	$"Tutorial"
]

var secret_clicks = 0
var minions_state = false

func _ready():
	for button in buttons:
		button.pressed.connect(play_sound)

func _on_Valid_pressed():
	$"../Shared_Interface_Sounds/Valid".play()
	await $"../Shared_Interface_Sounds/Valid".finished

func _on_Cancel_pressed():
	$"../Shared_Interface_Sounds/Cancel".play()
	await $"../Shared_Interface_Sounds/Cancel".finished

func _on_mouse_entered():
	if $"../Shared_Interface_Sounds/Leave".playing == true or $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../Shared_Interface_Sounds/Leave".playing == true or $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Leave".play()

func play_sound():
	$"../Drawer".volume_db = 0.0
	if $Secrets.button_pressed == true:
		secret_clicks += 1
		
		if secret_clicks % 10 == 0:
			if minions_state:
				$"../Minions_Off".play()
			else:
				$"../Minions_On".play()
			minions_state = !minions_state
		return

	if $Quit.button_pressed == true:
		$"../Drawer".volume_db = -5.0
	var pitches = [0.75, 1.0, 1.25]
	var pitch = pitches[randi() % pitches.size()]
	$"../Drawer".pitch_scale = pitch
	$"../Drawer".play()
