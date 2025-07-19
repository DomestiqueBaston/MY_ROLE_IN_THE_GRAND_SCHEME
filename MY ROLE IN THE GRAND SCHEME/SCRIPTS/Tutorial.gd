extends Node2D

signal done

var _json_data = [
	preload("res://JSON/TUTORIAL/tutorial_01.json").data,
	preload("res://JSON/TUTORIAL/tutorial_02.json").data,
	preload("res://JSON/TUTORIAL/tutorial_03.json").data,
	preload("res://JSON/TUTORIAL/tutorial_04.json").data
]

@onready var _label: RichTextLabel = $Node2D/Chalk_Mask/Tutorial_Text
@onready var _next_button: Button = $Node2D/Chalk_Mask/Next_Button
@onready var _anim_player: AnimationPlayer = $Typing_Animation
@onready var _typing_sound: AudioStreamPlayer = $Typing

var actual_value = 0.0
var pitch_values = [1.66, 0.66, 1.0]
var tutorial_text = ""
var current_json_index = 0
var click_delay = 1.0
var speed_factor = 1.0

func _ready():
	_next_button.pressed.connect(_on_next_button_pressed)
	_next_button.mouse_entered.connect(_on_next_button_mouse_entered)
	_next_button.mouse_exited.connect(_on_next_button_mouse_exited)
	load_tutorial_text()

func load_tutorial_text():
	tutorial_text = _json_data[current_json_index].get("tutorial", "")
	actual_value = 0.0
	_label.text = ""

func _process(_delta):
	if Input.is_action_pressed("Right_Click"):
		_anim_player.speed_scale = 10.0 * speed_factor
	else:
		_anim_player.speed_scale = 1.0 * speed_factor

	if tutorial_text:
		_label.text = tutorial_text

	if _label.visible_ratio < 1.0:
		if not _typing_sound.is_playing():
			# There is an unwanted delay with the typing sound...
			if _label.visible_ratio > actual_value:
				_typing_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]
				_typing_sound.play()
				actual_value += .001
			else:
				actual_value = 0.

func _on_next_button_pressed():
	Globals.valid_sound.play()
	current_json_index += 1

	if current_json_index == _json_data.size():
		set_process(false)
		_next_button.pressed.disconnect(_on_next_button_pressed)
		done.emit()
		return

	if current_json_index == _json_data.size() - 1:
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.size.y = 170
		_label.position.y = 98
		speed_factor = 2.5
		_next_button.text = "End of line"

	load_tutorial_text()
	_anim_player.seek(0, true)
	_anim_player.play("Display_Text")

func _on_next_button_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_next_button_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
