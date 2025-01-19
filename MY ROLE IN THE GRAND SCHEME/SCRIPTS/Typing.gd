extends Label

var actual_value = 0
var pitch_values = [1.2, 0.8, 1.0]

func _process(_delta):
	if $".".visible_characters <= 2354:
		if not $"../../../Typing".is_playing():
			# There is an unwanted delay with the typing sound...
			if $".".visible_characters > actual_value:
				var typing_sound = $"../../../Typing"
				typing_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]
				typing_sound.play()
				actual_value += 1
			else:
				actual_value = 0
