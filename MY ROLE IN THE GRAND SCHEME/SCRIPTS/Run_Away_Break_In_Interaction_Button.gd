extends Control

@onready var on_off = $"../../../On_Off"

func _ready():
	var button = $Bring_It_On
	button.mouse_entered.connect(Globals.on_mouse_entered.bind(button))
	button.mouse_exited.connect(Globals.on_mouse_exited.bind(button))
	button.pressed.connect(_on_bring_it_on_pressed)

func _on_bring_it_on_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	on_off.play("Disappearance")
	await on_off.animation_finished
