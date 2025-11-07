extends Node2D

@export var next_button: Button

signal done

func _ready():
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
		next_button.mouse_entered.connect(_on_next_button_mouse_entered)
		next_button.mouse_exited.connect(_on_next_button_mouse_exited)

func _on_next_button_pressed():
	Globals.valid_sound.play()
	done.emit()

func _on_next_button_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_next_button_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
