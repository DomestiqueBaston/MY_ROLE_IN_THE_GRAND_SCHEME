extends RichTextLabel

var actual_value = 0.0
var pitch_values = [1.2, 0.8, 1.0]

func _ready():
	# start processing when we actually need this thing
	set_process(false)

func _process(_delta):
	if $".".visible_ratio < 1.0:
		if not $"../../Typing".is_playing():
			# There is an unwanted delay with the typing sound...
			if $".".visible_ratio > actual_value:
				var typing_sound = $"../../Typing"
				typing_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]
				typing_sound.play()
				actual_value += .001
			else:
				actual_value = 0.
