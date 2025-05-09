extends Control

@onready var buttons = [
	$"Secrets", # Il y aura un truc SECRET à activer/désactiver dans ce tiroir !
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
	Globals.valid_sound.play()
	await Globals.valid_sound.finished

func _on_Cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func play_sound():
	#$"../Drawer".volume_db = 0.0
	if $Secrets.button_pressed == true:
		secret_clicks += 1
		
		if secret_clicks % 10 == 0:
			if minions_state:
				$"../Minions_Off".play()
			else:
				$"../Minions_On".play()
			minions_state = !minions_state
		return

	#if $Quit.button_pressed == true:
		#$"../Drawer".volume_db = -15.0
	var pitches = [0.75, 1.0, 1.25]
	var pitch = pitches[randi() % pitches.size()]
	$"../Drawer".pitch_scale = pitch
	$"../Drawer".play()
