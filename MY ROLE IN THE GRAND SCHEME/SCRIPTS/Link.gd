@tool
class_name Link extends Node2D

@export var pin1: Pin:
	set(value):
		if pin1 != value:
			if pin1:
				_disconnect_pin(pin1)
			pin1 = value
			if pin1:
				_connect_pin(pin1)
			_update_transform()
			_show_or_hide()

@export var pin2: Pin:
	set(value):
		if pin2 != value:
			if pin2:
				_disconnect_pin(pin2)
			pin2 = value
			if pin2:
				_connect_pin(pin2)
			_update_transform()
			_show_or_hide()

@export var type: Type = Type.HIDEOUT:
	set(value):
		if type != value:
			type = value
			_update_texture()
			_update_transparency()

@export var status: Status = Status.CONFIRMED:
	set(value):
		if status != value:
			status = value
			_update_texture()
			_update_transparency()

#
# Note that link types are assumed to begin at 0: see Globals.set_link_mask().
#
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

enum Status {
	## A confirmed link appears as a solid line.
	CONFIRMED,
	## A probable link appears as a dotted line.
	PROBABLE,
	## A new link appears as a dotted line, alternating violet with its actual
	## color.
	NEW
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

var _new_textures: Array[CompressedTexture2D] = [
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Blanc.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Gris.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Noir.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Rose.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Vert_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Orange.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Bleu_Clair.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Bleu_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Rouge.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Jaune.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Vert_Clair.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Marron.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Turquoise.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Bleu_Tres_Fonce.png"),
	preload("res://GRAPHICS/LINK_PIN/Pointille_Violet_Fonce_Violet_Clair.png")
]

# Pins that are linked to the middle of this link (at most one, for now).
var _follower_pins: Array[Pin]

func _ready():
	_update_transform()
	_update_texture()
	_show_or_hide()
	_update_transparency()
	if not Engine.is_editor_hint():
		Globals.link_visibility_changed.connect(_update_transparency)

func pause_collisions():
	$Link_Texture/Link_Collider.input_pickable = false

func resume_collisions():
	$Link_Texture/Link_Collider.input_pickable = true

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
		for pin in _follower_pins:
			pin.get_link_reference().queue_free()

func _connect_pin(pin: Pin):
	pin.moved.connect(_update_transform)
	pin.visibility_changed.connect(_show_or_hide)
	pin.set_link_reference(self)

func _disconnect_pin(pin: Pin):
	pin.moved.disconnect(_update_transform)
	pin.visibility_changed.disconnect(_show_or_hide)
	pin.set_link_reference(null)

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

	# update positions of follower pins

	for pin in _follower_pins:
		_update_follower_pin(pin)

func _update_texture():
	match status:
		Status.CONFIRMED:
			$Link_Texture.texture = _solid_textures[type]
		Status.PROBABLE:
			$Link_Texture.texture = _dotted_textures[type]
		Status.NEW:
			$Link_Texture.texture = _new_textures[type]

func _update_transparency():
	if not Engine.is_editor_hint():
		if Globals.is_link_visible(self):
			modulate.a = 1
		else:
			modulate.a = 0.25

func _show_or_hide():
	visible = pin1 and pin2 and pin1.visible and pin2.visible \
		and (Engine.is_editor_hint() or Globals.is_link_visible(self))
	for pin in _follower_pins:
		pin.visible = visible

func _on_link_collider_input_event(
		_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.link_right_click.emit(event.global_position, self)

func _on_link_collider_mouse_entered():
	Globals.mouse_entered_link.emit(self)

func _on_link_collider_mouse_exited():
	Globals.mouse_exited_link.emit(self)

##
## Registers a pin that is connected somewhere in the middle of this link.
## Registering follower pins allows the link to reposition them when it moves,
## and to show or hide them when its visibility changes.
##
func add_follower_pin(pin: Pin):
	_follower_pins.append(pin)
	_update_follower_pin(pin)
	pin.link_location_changed.connect(_update_follower_pin.bind(pin))

##
## Unregisters a follower pin registered previously by add_follower_pin().
##
func remove_follower_pin(pin: Pin):
	pin.link_location_changed.disconnect(_update_follower_pin.bind(pin))
	_follower_pins.erase(pin)

##
## Returns an array of follower pins that have been registered by calls to
## add_follower_pin().
##
func get_follower_pins() -> Array[Pin]:
	return _follower_pins

func _update_follower_pin(pin: Pin):
	pin.global_position = \
		lerp(pin1.global_position, pin2.global_position, pin.link_location)

##
## Temporarily increase the Z index of the link itself, the pins at its
## endpoints, and the pin of the other link connected to this link, if there is
## one.
##
func raise():
	z_index += 1
	pin1.z_index += 1
	pin2.z_index += 1
	for pin in _follower_pins:
		pin.z_index += 1

##
## Restore Z indexes after a call to raise().
##
func lower():
	z_index -= 1
	pin1.z_index -= 1
	pin2.z_index -= 1
	for pin in _follower_pins:
		pin.z_index -= 1
