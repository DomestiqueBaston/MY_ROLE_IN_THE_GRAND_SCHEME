extends Label

var json_path = "res://Random_Case_Names.json"
var json_data = {}

func _ready():
	# Charger le fichier JSON
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var file_content = file.get_as_text()
		file.close()

		var json_instance = JSON.new()
		var _result = json_instance.parse(file_content)
		
		# Stocker les données JSON
		json_data = json_instance.get_data()

func show_random_message():
	var part_1 = json_data["part_1"]
	var random_part_1 = part_1[randi() % part_1.size()]

	var part_2 = json_data["part_2"]
	var random_part_2 = part_2[randi() % part_2.size()]

	text = random_part_1 + random_part_2
