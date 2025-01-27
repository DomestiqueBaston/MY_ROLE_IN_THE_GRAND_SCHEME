extends Node2D

@onready var start_marker : Sprite2D = $Start
@onready var end_marker : Sprite2D = $End
@onready var texture_rect : TextureRect = $Papa_Link/Link_Texture
@onready var texture_y = 3

var selected_marker : Sprite2D = null  # Variable pour garder une référence du marqueur sélectionné
var dragging : bool = false  # Indicateur pour savoir si un marqueur est en train d'être déplacé

func _ready():
	texture_rect.visible = true
	# Définir le pivot du TextureRect pour qu'il soit à gauche au milieu (pour un alignement précis)
	texture_rect.pivot_offset = Vector2(0, texture_y / 2.0)

func _process(_delta):
	end_marker.position = ($"../Link_1/End".position + $"../Link_1/Start".position) / 2
	
	# Si un marqueur est sélectionné, déplacer ce marqueur avec la souris
	if selected_marker == start_marker and dragging:
		selected_marker.position = get_global_mouse_position()

	# Calculer la direction et la distance entre Start et End
	var direction = end_marker.position - start_marker.position
	var distance = direction.length()

	# Modifier uniquement la largeur du TextureRect pour qu'elle corresponde à la distance
	texture_rect.size.x = distance

	# Conserver la hauteur du TextureRect fixe
	texture_rect.size.y = texture_y

	# Positionner le Papa_Link à la position du Start
	$Papa_Link.position = start_marker.position

	# Faire en sorte que l'orientation du Papa_Link corresponde à la direction de Start à End
	$Papa_Link.rotation = direction.angle()

func _input(event):
	# Vérifier si un clic de souris a eu lieu
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:  # Si c'est un clic gauche
			if event.pressed:
				# Vérifier si le clic est sur l'un des marqueurs
				var mouse_position = get_global_mouse_position()

				# Vérifier si le clic est dans la zone du start_marker
				if start_marker.get_rect().has_point(start_marker.to_local(mouse_position)):
					# Sélectionner le marqueur Start pour déplacer
					selected_marker = start_marker
					dragging = true  # On commence à déplacer le marqueur
					
				# Vérifier si le clic est dans la zone du end_marker
				elif end_marker.get_rect().has_point(end_marker.to_local(mouse_position)):
					# Sélectionner le marqueur End pour déplacer
					selected_marker = end_marker
					dragging = true  # On commence à déplacer le marqueur

			else:
				# Quand le bouton de la souris est relâché, arrêter le déplacement
				selected_marker = null
				dragging = false  # Arrêter de déplacer
