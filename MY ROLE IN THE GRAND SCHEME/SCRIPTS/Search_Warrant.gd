extends Control

signal done

@onready var _anim: AnimationPlayer = $Typing_Animation
@onready var _sound: AudioStreamPlayer = $"../Typing"

var _actual_value = 0.0
var _pitch_values = [1.2, 0.8, 1.0]
var _confirmed: bool

func _ready():
	$No.pressed.connect(_on_no_pressed)
	$No.mouse_entered.connect(_on_mouse_entered)
	$No.mouse_exited.connect(_on_mouse_exited)

	$Yes.pressed.connect(_on_yes_pressed)
	$Yes.mouse_entered.connect(_on_mouse_entered)
	$Yes.mouse_exited.connect(_on_mouse_exited)

	set_process(false)

func reset():
	$Text.visible_characters = 0
	_actual_value = 0.0
	_confirmed = false
	set_process(true)
	_anim.play("Writing")

func get_confirmed():
	return _confirmed

func _process(_delta):
	if $Text.visible_ratio >= 0.0 and $Text.visible_ratio < 1.0:
		if not _sound.is_playing():
			# There is an unwanted delay with the typing sound...
			if $Text.visible_ratio > _actual_value:
				_sound.pitch_scale = _pitch_values.pick_random()
				_sound.play()
				_actual_value += .001
			else:
				_actual_value = 0.
	else:
		set_process(false)

func _on_yes_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	_confirmed = true
	done.emit()

func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	_confirmed = false
	done.emit()

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
