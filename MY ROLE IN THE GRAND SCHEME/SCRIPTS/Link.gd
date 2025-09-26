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
			_update_tooltip()

@export var status: Status = Status.CONFIRMED:
	set(value):
		if status != value:
			status = value
			_update_texture()
			_update_transparency()
			_update_tooltip()

## A blocked link cannot be changed or deleted by the player.
var blocked: bool = false

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
	INCONSISTENCY,
	WITNESS,
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

static var _link_scene = preload("res://SCENES/Link.tscn")

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

# Pins that are linked to the middle of this link.
var _follower_pins: Array[Pin]

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func _ready():
	_update_transform()
	_update_texture()
	_show_or_hide()
	_update_transparency()
	_update_tooltip()
	if not Engine.is_editor_hint():
		Globals.link_visibility_changed.connect(_update_transparency)

func pause_collisions():
	$Link_Texture/Link_Collider.input_pickable = false

func resume_collisions():
	$Link_Texture/Link_Collider.input_pickable = true

#
# When a Link is deleted, delete the pins at its endpoints, and any other
# links connected to it, too.
#
func _notification(what: int):
	if what == NOTIFICATION_PREDELETE and not Engine.is_editor_hint():
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

func _update_tooltip():
	if not Engine.is_editor_hint():
		var tooltip = Type.keys()[type].capitalize()
		if status == Status.NEW:
			tooltip = "New " + tooltip
		$Link_Texture.tooltip_text = tooltip

func _show_or_hide():
	if not Engine.is_editor_hint():
		visible = pin1 and pin2 and pin1.visible and pin2.visible \
			and Globals.is_link_visible(self)
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

##
## Returns true if a link of the given type can be created between the given
## endpoints. At least one of the endpoints must be a card; the other can be
## either a card or a link. If either endpoint is null, only the type of the
## other endpoint is taken into consideration. So, for example, if endpt1 is an
## ObjectCard and endpt2 is null, the function returns true for link types that
## can sometimes be connected to an ObjectCard.
##
static func is_link_valid(endpt1: Node2D, endpt2: Node2D, link_type: Type) -> bool:
	if endpt1 == null and endpt2 == null:
		return true

	if endpt1 == null or endpt2 == null:
		var endpt = endpt1 if endpt2 == null else endpt2
		match link_type:
			Type.HIDEOUT, Type.HOME, Type.WORK, Type.HANGOUT:
				if endpt is LocationCard:
					return true
				if endpt is NpcCard:
					var max_links = 2 if link_type == Type.HANGOUT else 1
					return endpt.find_links(link_type).size() < max_links
				return false
			Type.DEBT, Type.INTIMACY, Type.FRIEND, Type.ENEMY, Type.ACQUAINTANCE, Type.IDEOLOGY:
				return endpt is NpcCard
			Type.GUILT:
				return endpt is NpcCard or endpt is ObjectCard
			Type.INCONSISTENCY:
				return true
			Type.WITNESS:
				return endpt is NpcCard or endpt is Link
			Type.PROPERTY:
				return endpt is ObjectCard or endpt is NpcCard or endpt is LocationCard
			Type.FOUND:
				return endpt is ObjectCard or endpt is LocationCard
			_:
				return true

	if endpt1 == endpt2:
		return false

	var ok

	match link_type:
		Type.HIDEOUT, Type.HOME, Type.WORK, Type.HANGOUT:
			ok = (endpt1 is NpcCard and endpt2 is LocationCard) \
				or (endpt1 is LocationCard and endpt2 is NpcCard)
			if ok:
				var npc: NpcCard = endpt1 if endpt1 is NpcCard else endpt2
				var max_links = 2 if link_type == Type.HANGOUT else 1
				ok = npc.find_links(link_type).size() < max_links
		Type.DEBT, Type.INTIMACY, Type.FRIEND, Type.ENEMY, Type.ACQUAINTANCE, Type.IDEOLOGY:
			ok = endpt1 is NpcCard and endpt2 is NpcCard
		Type.GUILT:
			ok = (endpt1 is NpcCard and endpt2 is NpcCard) \
				or (endpt1 is NpcCard and endpt2 is ObjectCard) \
				or (endpt1 is ObjectCard and endpt2 is NpcCard)
		Type.INCONSISTENCY:
			ok = true
		Type.WITNESS:
			ok = (endpt1 is NpcCard and endpt2 is Link and endpt2.type != Type.WITNESS) \
				or (endpt1 is Link and endpt1.type != Type.WITNESS and endpt2 is NpcCard)
		Type.PROPERTY:
			ok = (endpt1 is ObjectCard and (endpt2 is NpcCard or endpt2 is LocationCard)) \
				or (endpt2 is ObjectCard and (endpt1 is NpcCard or endpt1 is LocationCard))
		Type.FOUND:
			ok = (endpt1 is ObjectCard and endpt2 is LocationCard) \
				or (endpt1 is LocationCard and endpt2 is ObjectCard)
		_:
			ok = true

	return ok and not is_link_found(endpt1, endpt2, link_type)

##
## Returns true if there is a link of the given type between the given two nodes
## (one must be a card, the other can be a card or a link).
##
static func is_link_found(source: Node2D, target: Node2D, link_type: Type) -> bool:
	var card
	var card_or_link

	if source is Card:
		card = source
		card_or_link = target
	elif target is Card:
		card = target
		card_or_link = source
	else:
		return false

	for link in card.find_links(link_type):
		if card_or_link in [link.pin1.backing, link.pin2.backing]:
			return true

	return false

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.LINK

#
# For save/load.
#
func get_unique_id():
	return "lnk%d" % _unique_id

#
# For save/load.
#
func get_referenced_objects():
	var refs = []
	if pin1:
		refs.append(pin1)
	if pin2:
		refs.append(pin2)
	for pin in _follower_pins:
		refs.append(pin)
	return refs

#
# For save/load.
#
func get_json_dict():
	var dict = {
		"type": type,
		"status": status,
		"blocked": blocked
	}
	if pin1:
		dict["pin1"] = pin1.get_unique_id()
	if pin2:
		dict["pin2"] = pin2.get_unique_id()
	if _follower_pins:
		var pin_refs = []
		for pin in _follower_pins:
			pin_refs.append(pin.get_unique_id())
		dict["follower_pins"] = pin_refs
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	type = dict.type
	status = dict.status
	blocked = dict.get("blocked", false)
	if "pin1" in dict:
		pin1 = catalog[dict.pin1]
	if "pin2" in dict:
		pin2 = catalog[dict.pin2]
	for ref in dict.get("follower_pins", []):
		_follower_pins.append(catalog[ref])

#
# For save/load.
#
static func allocate() -> Object:
	return _link_scene.instantiate()
