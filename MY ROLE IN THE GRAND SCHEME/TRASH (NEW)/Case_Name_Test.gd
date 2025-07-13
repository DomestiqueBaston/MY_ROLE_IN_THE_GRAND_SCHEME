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
	var alpha = json_data["alpha"]
	var random_alpha = alpha[randi() % alpha.size()]

	var beta = json_data["beta"]
	var random_beta = beta[randi() % beta.size()]

	text = random_alpha + random_beta
