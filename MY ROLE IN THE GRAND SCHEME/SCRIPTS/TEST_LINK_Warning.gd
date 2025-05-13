extends Sprite2D

@export var link_texture_path: NodePath  # Texture servant de référence pour définir la position du Warning
@export var offset_y := -10

var link_texture: TextureRect

func _ready():
	link_texture = get_node(link_texture_path) as TextureRect

func _process(_delta):
	if link_texture == null:
		return

	var center_local = link_texture.size / 4
	var global_center = link_texture.get_global_transform_with_canvas() * center_local
	var global_offset = Vector2(0, offset_y)

	global_position = global_center + global_offset
