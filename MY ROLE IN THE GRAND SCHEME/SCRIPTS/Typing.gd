extends RichTextLabel

var actual_value = 0.0
var pitch_values = [1.2, 0.8, 1.0]
var tutorial_text = ""

func _ready():
	# Charge le fichier JSON au démarrage
	load_tutorial_text()

func load_tutorial_text():
	# Charge et "parse"r" le fichier JSON
	var file = FileAccess.open("res://JSON/TUTORIAL/tutorial_01.json", FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()
	
	# Crée une instance de JSON et "parse" les données
	var json_parser = JSON.new()
	json_parser.parse(json_data)
	
	# Récupére directement le texte du tutoriel
	tutorial_text = json_parser.get_data().get("tutorial", "")

func _process(_delta):
	if $".".visible_ratio < 1.0:
		if not $"../../../Typing".is_playing():
			# Il y a un délai indésirable avec le son de frappe...
			if $".".visible_ratio > actual_value:
				var typing_sound = $"../../../Typing"
				typing_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]
				typing_sound.play()
				actual_value += .001
			else:
				actual_value = 0.

	# Si le texte du tutoriel est disponible, on l'affiche dans le label
	if tutorial_text != "":
		text = tutorial_text
