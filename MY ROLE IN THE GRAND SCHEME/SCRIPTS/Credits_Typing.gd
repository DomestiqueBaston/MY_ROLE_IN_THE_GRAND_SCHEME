extends RichTextLabel

signal done

@onready var _typing_sound = $"../../Typing"
var _actual_value = 0.0
var _pitch_values = [1.2, 0.8, 1.0]

func _process(_delta):
	if visible_ratio > 0.0 && visible_ratio < 1.0:
		if not _typing_sound.is_playing():
			# There is an unwanted delay with the typing sound...
			if visible_ratio > _actual_value:
				_typing_sound.pitch_scale = _pitch_values[randi() % _pitch_values.size()]
				_typing_sound.play()
				_actual_value += .001
			else:
				_actual_value = 0.
	if visible_ratio > 0.999:
		set_process(false)
		done.emit()
