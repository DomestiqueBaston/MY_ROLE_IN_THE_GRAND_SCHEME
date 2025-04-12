extends Label


var json_path = "res://JSON/NARRATION/Case_Introduction.json"


func _ready():
	var json_data = load_json()

	var categories = json_data.keys()

	var random_category = categories[randi() % categories.size()]
	print("Catégorie sélectionnée : ", random_category)

	var theme_data = json_data[random_category]

	var generated_text = ""
	for part in theme_data:
		var choices = part["choices"]
		var random_choice = choices[randi() % choices.size()]
		generated_text += random_choice

	generated_text += "\n" + "..."

	text = generated_text.strip_edges()

func load_json() -> Variant:
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()
	return parse_json(json_data)

func parse_json(json_text: String) -> Variant:
	var json = JSON.new()
	json.parse(json_text)
	return json.get_data()
