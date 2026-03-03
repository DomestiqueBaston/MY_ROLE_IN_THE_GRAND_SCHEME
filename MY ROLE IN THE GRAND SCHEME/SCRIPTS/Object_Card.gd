@tool
class_name ObjectCard extends Card

@export var is_object_evidence: bool:
	set(value):
		if is_object_evidence != value:
			is_object_evidence = value
			if is_node_ready():
				_update_appearance()

@export var evidence_color: Color = Color("#525252"):
	set(value):
		evidence_color = value
		if is_node_ready() and is_object_evidence:
			_update_appearance()

## ID of corresponding entry in object database.
var database_id: String

static var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data
static var _card_scene = preload("res://SCENES/Object_Card.tscn")

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func get_card_type():
	return CardType.OBJECT

func _ready():
	super()
	_update_appearance()

func _update_appearance():
	$Card_Mask/Card_BG/Evidence.visible = is_object_evidence

	if is_object_evidence:
		$Card_Mask/Card_BG/Card_Outlines.self_modulate = evidence_color
		$Card_Drag.modulate = evidence_color
	else:
		$Card_Mask/Card_BG/Card_Outlines.self_modulate = Color.WHITE
		$Card_Drag.modulate = Color.WHITE

func get_location() -> LocationCard:
	return get_one_connection(Link.Type.FOUND)

##
## Returns true if the object's "automatic_owners_reveal" flag is set, meaning
## that, when the object is revealed to the players, its owners are revealed,
## too.
##
func get_owner_reveal() -> bool:
	return _object_data[database_id].get("automatic_owners_reveal", false)

static func create_card(id: String) -> ObjectCard:
	var card = _card_scene.instantiate()
	var object_info = _object_data[id]
	card.card_name = object_info["name"]
	card.description = object_info["description"]
	card.database_id = id
	return card

func print_object():
	if is_object_evidence:
		print("%s (evidence):" % get_display_name())
	else:
		print("%s:" % get_display_name())
	print_connections_of_type("found", Link.Type.FOUND)
	print_connections_of_type("property", Link.Type.PROPERTY)

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.OBJECT_CARD

#
# For save/load.
#
func get_unique_id():
	return "obj%d" % _unique_id

#
# For save/load.
#
func get_json_dict():
	var dict = super()
	if is_object_evidence:
		dict["is_object_evidence"] = is_object_evidence
	dict["database_id"] = database_id
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	is_object_evidence = dict.get("is_object_evidence", false)
	database_id = dict["database_id"]
	var object_info = _object_data[database_id]
	card_name = object_info["name"]
	description = object_info["description"]

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
