extends RichTextLabel

var json_path = "res://JSON/NARRATION/Paranoia.json"
var json_data = {}

func _ready():
	# Charger et parser le fichier JSON
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var file_content = file.get_as_text()
		file.close()

		var json_instance = JSON.new()
		var _result = json_instance.parse(file_content)
		json_data = json_instance.get_data()

		# Afficher un message généré dynamiquement
		show_random_message()

func show_random_message():	
	# Choisir un bloc aléatoire dans "blocks"
	var blocks = json_data["blocks"]

	# Créer un tableau pour stocker les choix des blocs
	var selected_choices = []

	# Pour chaque bloc, sélectionner un message aléatoire
	for block in blocks:
		var choices = block["choices"]
		
		# Sélectionner un choix aléatoire parmi les choices de ce bloc
		var random_choice = choices[randi() % choices.size()]
		selected_choices.append(random_choice)

	# Combiner tous les choix sélectionnés en un seul texte
	var final_text = ""
	for choice in selected_choices:
		final_text += choice + "\n"  # Ajouter un saut de ligne après chaque message

	# Afficher le texte généré dans le RichTextLabel avec le BBCode activé
	text = final_text
