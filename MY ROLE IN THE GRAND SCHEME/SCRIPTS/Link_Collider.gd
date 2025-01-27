extends CollisionShape2D

@onready var link_texture : TextureRect = $"../.."
@onready var link_collider : Area2D = $".."
@onready var collider : CollisionShape2D = $"."

# /!\
# Ce script fonctionne sauf lorsque plusieurs instances de cette scène sont crées :
# à ce moment-là, la taille et l'offset de "Collider" (CollisionShape2D)
# dans la dernière instance sont répercutés sur les précédentes.
# /!\

func _process(_delta):
	# Mettre à jour la taille du Collider pour qu'elle soit la même que Link_Texture
	update_collider_size_and_position()
	# Ajustement de la position pour que le Collider soit centré sur Link_Texture
	update_collider_position()

# Fonction pour mettre à jour la taille du Collider
func update_collider_size_and_position():
	if shape is RectangleShape2D:
		var rectangle_shape = shape
		# Mise à jour de la taille du Collider pour qu'elle soit la même que Link_Texture
		rectangle_shape.extents.x = link_texture.size.x / 2
		rectangle_shape.extents.y = link_texture.size.y / 2

# Fonction pour ajuster la position du Collider
func update_collider_position():
	# Déplacer le Collider pour qu'il soit centré sur Link_Texture
	collider.position.x = link_texture.size.x / 2
