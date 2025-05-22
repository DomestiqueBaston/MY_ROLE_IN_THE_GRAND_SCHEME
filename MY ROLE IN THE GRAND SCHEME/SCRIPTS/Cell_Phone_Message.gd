extends Label

var actual_value = 0.0
var pitch_values = [1.1, 0.95, 1.0]
var json_path = "res://JSON/NARRATION/SMS.json"
var json_data = {}
var signatures = ["Anonymous", "Le corbeau", "D.B."]

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

	# Choisir une signature aléatoire
	var random_signature = signatures[randi() % signatures.size()]

	# Ajouter la signature au message
	text = messages[random_message_key] + "\n\n" + random_signature
