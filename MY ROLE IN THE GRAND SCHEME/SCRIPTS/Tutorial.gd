extends Node2D

@export var next_button: Button

signal done

func _ready():
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
		next_button.mouse_entered.connect(Globals.on_mouse_entered)
		next_button.mouse_exited.connect(Globals.on_mouse_exited)

func _on_next_button_pressed():
	Globals.valid_sound.play()
	done.emit()
