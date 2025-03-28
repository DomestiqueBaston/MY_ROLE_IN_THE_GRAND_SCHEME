extends Sprite2D

@export var anim_expand : String = "Expand_Card"  # Nom de l'animation pour agrandir
@export var anim_reduce : String = "Reduce_Card"  # Nom de l'animation pour réduire
@export var anim_reset : String = "RESET"  # Nom de l'animation pour réinitialiser

var current_animation : String
var card : CollisionShape2D  # Un seul collider nommé "Card"

# Fonction appelée au démarrage
func _ready():
	# On récupère la référence du CollisionShape2D (Card)
	card = $Card_Colliders/Card
	
	current_animation = anim_reset  # Commence avec l'animation RESET
	play_animation(current_animation)

# Fonction appelée à chaque frame
func _process(_delta):
	# Ça "marche" pour la démo mais sinon, tous les z_index sont à revoir
	# dans le projet pour pouvoir gérer mieux les "couches"...
	#if is_mouse_in_collision(card):
		#$"..".z_index = 1
	#else:
		#$"..".z_index = 0

	if Input.is_action_just_pressed("Left_Click"):
		if is_mouse_in_collision(card):
			# Si l'animation en cours est RESET (carte déjà "expandée"), on ne fait rien
			if current_animation == anim_reset:
				# La carte est déjà dans son état "expandé", donc on ne joue pas Expand_Card
				play_animation(anim_reduce)  # Commence par Reduce_Card après Reset
				return
			# Sinon, alterner entre Reduce_Card et Expand_Card
			if current_animation == anim_reduce:
				play_animation(anim_expand)
			elif current_animation == anim_expand:
				play_animation(anim_reduce)

# Fonction pour vérifier si la souris est dans la zone de la forme
func is_mouse_in_collision(collision_shape: CollisionShape2D) -> bool:
	var shape = collision_shape.shape
	var mouse_position = get_global_mouse_position()
	
	# Applique les transformations globales de la CollisionShape2D
	var shape_global_position = collision_shape.global_position
	var shape_global_scale = collision_shape.scale
	
	# Déplace la position de la souris dans l'espace de la CollisionShape2D
	var mouse_local_position = (mouse_position - shape_global_position) / shape_global_scale

	# Vérification pour une forme rectangulaire
	if shape is RectangleShape2D:
		var rect = shape as RectangleShape2D
		return rect.extents.x > mouse_local_position.x and mouse_local_position.x > -rect.extents.x and rect.extents.y > mouse_local_position.y and mouse_local_position.y > -rect.extents.y
	
	# Vérification pour une forme circulaire (inutile)
	elif shape is CircleShape2D:
		var circle = shape as CircleShape2D
		return mouse_local_position.length() <= circle.radius
	
	# Ajoute d'autres formes ici si nécessaire (Polygon, etc.)
	return false

# Joue l'animation spécifiée
func play_animation(anim_name: String):
	$"../Card_Animations".play(anim_name)
	current_animation = anim_name  # Met à jour l'animation actuelle
