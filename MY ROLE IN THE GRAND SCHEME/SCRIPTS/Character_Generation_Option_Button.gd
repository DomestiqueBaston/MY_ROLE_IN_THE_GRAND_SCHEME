extends OptionButton

var description_array = []  # Initialisation de description_array

func _ready():
	# Rendre le popup transparent
	get_popup().transparent = true
	get_popup().max_size = Vector2(162, 101)
	
	var file = FileAccess.open("res://JSON/PLAYER/Background_Descriptions.json", FileAccess.READ)
	
	var json_data = file.get_as_text()
	file.close()
	
	var backgrounds = JSON.new()
	var _parse_result = backgrounds.parse(json_data)
	
	var data = backgrounds.get_data()

	var backgrounds_array = data["Background"]

	clear()

	# Ajouter les items de backgrounds et remplir description_array avec les descriptions
	for i in range(backgrounds_array.size()):
		var item = backgrounds_array[i]
		add_item(item["profession"])
		description_array.append(item["description"])  # Remplir description_array avec les descriptions

	# Ajouter un séparateur "Select a background" à la fin
	if backgrounds_array.size() > 0:
		add_separator("Select a background")  # Ajouter le séparateur avec texte
		# Sélectionner le dernier item ajouté (le séparateur)
		self.selected = get_item_count() - 1  # Sélectionner l'avant-dernier item visible, car le séparateur est ajouté en dernier

# Signal émis lorsque l'utilisateur sélectionne un item
func _on_item_selected(index: int):
	$"../../Valid".play()

	# Vérifier si l'index est valide avant d'y accéder
	if index >= 0 and index < description_array.size():
		var description = description_array[index]
		$"../../../Story".text = description
	else:
		print("Index invalide")


func _on_button_down():
	$"../../Hover".play()

func _on_button_up():
	$"../../Leave".play()
