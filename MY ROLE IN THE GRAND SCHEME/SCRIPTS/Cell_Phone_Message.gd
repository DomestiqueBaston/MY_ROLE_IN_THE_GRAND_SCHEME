extends Label


var actual_value = 0.0
var pitch_values = [1.66, 0.66, 1.0]
var json_path = "res://JSON/NARRATION/SMS.json"
var json_data = {}


func _ready():
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var file_content = file.get_as_text()
		file.close()

		var json_instance = JSON.new()
		var _result = json_instance.parse(file_content)
		
		json_data = json_instance.get_data()

		show_random_message()

func show_random_message():
	var categories = json_data.keys()
	var random_category = categories[randi() % categories.size()]
	
	var messages = json_data[random_category]
	var message_keys = messages.keys()
	var random_message_key = message_keys[randi() % message_keys.size()]

	text = messages[random_message_key]

func _process(_delta):
	if $".".visible_ratio < 1.0:
		if not $"../../../Typing".is_playing():
			# There is an unwanted delay with the typing sound...
			if $".".visible_ratio > actual_value:
				var typing_sound = $"../../../Typing"
				typing_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]
				typing_sound.play()
				actual_value += .001
			else:
				actual_value = 0.
