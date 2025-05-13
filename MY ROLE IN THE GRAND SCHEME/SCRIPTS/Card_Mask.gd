extends Sprite2D

# Fonction appelée au démarrage
func _ready():
	# -- Placement aléatoire du texture.offset par pas de 10
	var offset_x = -10 * randi_range(0, 12)  # 0 à -120 par pas de 10
	var offset_y = -10 * randi_range(0, 3)   # 0 à -30 par pas de 10
	$Card_BG.offset = Vector2(offset_x, offset_y)

# Fonction appelée à chaque frame
func _process(_delta):
	# -- AJOUT : synchronisation dynamique de l'ombre avec la transparence de la carte
	# L’ombre (Card_Shadow) devient plus transparente si la carte l’est aussi
	var card_alpha := modulate.a  # Alpha (transparence) de la carte actuelle
	var target_shadow_alpha := card_alpha * 0.3  # On veut max 30% d’opacité pour l’ombre

	var shadow_material: ShaderMaterial = $"../Card_Shadow".material
	if shadow_material:
		shadow_material.set_shader_parameter("shadow_color", Color(0, 0, 0, target_shadow_alpha))
