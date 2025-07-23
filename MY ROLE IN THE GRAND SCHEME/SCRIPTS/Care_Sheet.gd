extends Node2D

signal done

var _confirmed: bool

@onready var _note = $Note/Doctor_F
@onready var _typing_sound = $Typing

var _actual_value = 0.0
var _pitch_values = [1.2, 0.8, 1.0]

func _ready():
	$Note/Yes.pressed.connect(_on_yes_pressed)
	$Note/Yes.mouse_entered.connect(_on_any_button_entered)
	$Note/Yes.mouse_exited.connect(_on_any_button_exited)

	$Note/No.pressed.connect(_on_no_pressed)
	$Note/No.mouse_entered.connect(_on_any_button_entered)
	$Note/No.mouse_exited.connect(_on_any_button_exited)

	set_process(false)

func _process(_delta):
	if _note.visible_ratio < 1.0:
		if not _typing_sound.is_playing():
			# There is an unwanted delay with the typing sound...
			if _note.visible_ratio > _actual_value:
				_typing_sound.pitch_scale = _pitch_values.pick_random()
				_typing_sound.play()
				_actual_value += .001
			else:
				_actual_value = 0.0
	else:
		set_process(false)

func reset():
	$Note/Doctor_F.visible_characters = 0
	$Care_Sheet_Animation.play("Writing")
	_actual_value = 0.0
	set_process(true)

func get_confirmed() -> bool:
	return _confirmed

func _on_yes_pressed():
	set_process(false)
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	_confirmed = true
	done.emit()

func _on_no_pressed():
	set_process(false)
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	_confirmed = false
	done.emit()

func _on_any_button_entered():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.hover_sound.play()

func _on_any_button_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
