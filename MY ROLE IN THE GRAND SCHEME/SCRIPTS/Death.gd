extends Node2D

@export var text = "\
In Memoriam: {player_name}, Who Unfortunately Never Quite Got It Right

This private investigator passed away, leaving behind a career marked more by \
persistence than triumph. His methods, often unorthodox, led him down \
countless false paths, and his conclusions rarely hit the mark. Yet, his drive \
to uncover the truth never wavered, even when the cases grew colder and the \
answers seemed forever out of reach. Though he never solved the big case or \
achieved the recognition he sought, his unwavering dedication to justice was \
undeniable. In the end, his legacy is not one of success, but of relentless \
pursuit, never satisfied, always searching, even when the truth remained just \
beyond his grasp.

Condolences to the family, if applicable."

signal done

func _ready():
	$Death_Note/Quit.pressed.connect(_on_quit_pressed)
	$Death_Note/Quit.mouse_entered.connect(_on_mouse_entered)
	$Death_Note/Quit.mouse_exited.connect(_on_mouse_exited)
	$Death_Note/Necrology.text = text.format(GameState.player)

func _on_quit_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	done.emit()

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
