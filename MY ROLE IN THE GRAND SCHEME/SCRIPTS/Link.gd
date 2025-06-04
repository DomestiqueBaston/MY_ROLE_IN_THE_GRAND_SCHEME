@tool
class_name Link extends Node2D

@export var pin1: Pin:
	set(value):
		if pin1 != value:
			if pin1:
				pin1.moved.disconnect(_pin_moved)
				pin1.visibility_changed.disconnect(_pin_visibility_changed)
			pin1 = value
			if pin1:
				pin1.moved.connect(_pin_moved)
				pin1.visibility_changed.connect(_pin_visibility_changed)
			_update_transform()
			_show_or_hide()

@export var pin2: Pin:
	set(value):
		if pin2 != value:
			if pin2:
				pin2.moved.disconnect(_pin_moved)
				pin2.visibility_changed.disconnect(_pin_visibility_changed)
			pin2 = value
			if pin2:
				pin2.moved.connect(_pin_moved)
				pin2.visibility_changed.connect(_pin_visibility_changed)
			_update_transform()
			_show_or_hide()

@export var type: Type = Type.HIDEOUT:
	set(value):
		type = value
		_update_texture()

@export var is_confirmed: bool = true:
	set(value):
		is_confirmed = value
		_update_texture()

enum Type {
	HIDEOUT,
	DEBT,
	GUILT,
	INTIMACY,
	FRIEND,
	ENEMY,
	ACQUAINTANCE,
	IDEOLOGY,
	CONTRADICTION,
	CONFIRMATION,
	PROPERTY,
	HOME,
	WORK,
	HANGOUT,
	FOUND
}

var _solid_textures: Array[CompressedTexture2D] = [
	preload("res://GRAPHICS/LINK_PIN/Plein_Blanc.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Gris.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Noir.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Rose.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Vert_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Orange.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Bleu_Clair.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Bleu_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Rouge.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Jaune.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Vert_Clair.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Marron.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Turquoise.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Bleu_Tres_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Plein_Violet_Clair.png")
]

var _dotted_textures: Array[CompressedTexture2D] = [
	preload("res://GRAPHICS/LINK_PIN/Pointille_Blanc.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Gris.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Noir.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Rose.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Vert_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Orange.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Bleu_Clair.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Bleu_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Rouge.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Jaune.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Vert_Clair.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Marron.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Turquoise.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Bleu_Tres_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Clair.png")
]

func _ready():
	_update_transform()
	_update_texture()
	_show_or_hide()

func _exit_tree():
	if not Engine.is_editor_hint():
		var old_pin1 = pin1
		var old_pin2 = pin2
		pin1 = null
		pin2 = null
		if old_pin1:
			old_pin1.queue_free()
		if old_pin2:
			old_pin2.queue_free()

func _pin_moved():
	_update_transform()

func _pin_visibility_changed():
	_show_or_hide()

func _update_transform():
	if not (pin1 and pin2):
		return

	# update texture

	var pos1 = pin1.global_position
	var pos2 = pin2.global_position
	var rot = pos1.angle_to_point(pos2)
	var thickness = $Link_Texture.size.y
	$Link_Texture.size.x = pos1.distance_to(pos2)
	$Link_Texture.rotation = rot
	$Link_Texture.global_position = pos1 - Vector2(0, thickness/2).rotated(rot)
	
	# update collider shape

	var collider = $Link_Texture/Link_Collider/Collider
	var rectangle_shape = collider.shape
	if rectangle_shape is RectangleShape2D:
		rectangle_shape.size = $Link_Texture.size
		collider.position = $Link_Texture.size / 2

func _update_texture():
	if is_confirmed:
		$Link_Texture.texture = _solid_textures[type]
	else:
		$Link_Texture.texture = _dotted_textures[type]

func _show_or_hide():
	visible = pin1 and pin2 and pin1.visible and pin2.visible

func _on_link_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.link_right_click.emit(event.global_position, self)
