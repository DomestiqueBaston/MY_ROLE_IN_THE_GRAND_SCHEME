extends Node2D

@export var text = "\
In Memoriam: A Private Investigator, Who Unfortunately Never Quite Got It Right.

{player_name} passed away, leaving behind a career marked more by \
persistence than triumph. His methods, often unorthodox, led him down \
countless false paths, and his conclusions rarely hit the mark. Yet, his drive \
to uncover the truth never wavered, even when the cases grew colder and the \
answers seemed forever out of reach. Though he never solved the big case or \
achieved the recognition he sought, his unwavering dedication to justice was \
undeniable. In the end, his legacy is not one of success, but of relentless \
pursuit, never satisfied, always searching, even when the truth remained just \
beyond his grasp.

Condolences to the family, if applicable."

@export var final_case_text = "\
In Memoriam: A Private Investigator Who Refused to Move On.

{player_name} died after the final days were consumed by a mystery that had \
taken over every part of life. What began as a sudden fixation turned into a \
consuming mental spiral.

Every loose end became a pattern. Every coincidence, evidence. Every silence, \
proof of something unseen. Sleep, stability, and judgment were gradually traded \
for an answer that kept receding.

Some say death came from exhaustion. Others say something far uglier than that. \
The truth is, the investigation ended the only way it realistically could...

Just another unsolved case.

Condolences to the family, if applicable."

signal done

func _ready():
	$Death_Note/Quit.pressed.connect(_on_quit_pressed)
	$Death_Note/Quit.mouse_entered.connect(Globals.on_mouse_entered)
	$Death_Note/Quit.mouse_exited.connect(Globals.on_mouse_exited)
	if GameState.is_final_case():
		$Death_Note/Necrology.text = final_case_text.format(GameState.player)
	else:
		$Death_Note/Necrology.text = text.format(GameState.player)

func _on_quit_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	done.emit()
