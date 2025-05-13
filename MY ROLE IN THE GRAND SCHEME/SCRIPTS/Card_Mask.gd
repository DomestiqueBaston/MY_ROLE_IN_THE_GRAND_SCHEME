extends Sprite2D

func _ready():
	# -- Placement aléatoire du texture.offset par pas de 10
	var offset_x = -10 * randi_range(0, 12)  # 0 à -120 par pas de 10
	var offset_y = -10 * randi_range(0, 3)   # 0 à -30 par pas de 10
	$Card_BG.offset = Vector2(offset_x, offset_y)
