extends Sprite2D

@export var anim_expand : String = "Expand_Card"  # Nom de l'animation pour agrandir
@export var anim_reduce : String = "Reduce_Card"  # Nom de l'animation pour réduire
@export var anim_reset : String = "RESET"  # Nom de l'animation pour réinitialiser

var current_animation : String
var card : CollisionShape2D  # Un seul collider nommé "Card"
var was_hovered : bool = false  # Pour suivre l'état de survol précédent

# Fonction appelée au démarrage
func _ready():
	# On récupère la référence du CollisionShape2D (Card)
	card = $Card_Colliders/Card
	
	current_animation = anim_reset  # Commence avec l'animation RESET
	play_animation(current_animation)

# Fonction appelée à chaque frame
func _process(_delta):
	# Ce qui suit "marche" pour la démo mais sinon, tous les z_index sont à revoir
	# dans le projet (voir Nouveau_système_v14.odt à la fin) pour pouvoir mieux
	# gérer les "couches" (il sera aussi certainement judiceux de regarder les scènes
	# Interaction_Structure.tscn et Main_Structure.tscn).
	# Dans ce sens, j'ai modifié quelques z_index en manuel
	# (dans Main.tscn et Interaction.tscn) mais il faudra que ça
	# soit géré par le script sinon, ça va être la misère.
	# Voir aussi commentaires plus bas
	
	if is_mouse_in_collision(card):
		$"..".z_index = 1
	else:
		$"..".z_index = 0

	# -- Ajout : détection de survol de la souris et gestion des animations de shadow
	# Il faudra aussi faire en sorte que seule LA carte sous la souris affiche son
	# ombre. Même quand plusieurs cartes se chevauchent.
	# Voir aussi commentaires plus bas
	var is_hovered = is_mouse_in_collision(card)

	if is_hovered and not was_hovered:
		$"../Shadow_Animations".play("Shadow_On")
	elif not is_hovered and was_hovered:
		$"../Shadow_Animations".play("Shadow_Off")
	was_hovered = is_hovered

	if Input.is_action_just_pressed("Left_Click"):
		if is_hovered:
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

## Je n'arrive pas à faire en sorte que lorsque deux instances de carte
## se trouvent l'une sur l'autre, que la partie cachée de celle du dessous
## ne reçoive pas les clics de souris (ni même ne voit la souris ?)...

## Dans Interarction.tscn, lorsque l'on a une ribambelle de cartes les unes sur
## les autres en ligne horizontale (ou verticale), celle sous le curseur de la
## souris devra passer devant les autres et aussi bouger un peu en +Y ou -Y,
## à voir en fonction des endroits à l'écran. L'idéal serait même que celles
## autour de la carte en question bougent en Y aussi mais de 33% et celles
## d'encore une carte plus loin de 66% pour faire comme une onde !

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

# -- Nouvelle fonction : Joue l'animation de survol (ombre)
func play_shadow_animation(anim_name: String):
	$"../Card_Animations".play(anim_name)
