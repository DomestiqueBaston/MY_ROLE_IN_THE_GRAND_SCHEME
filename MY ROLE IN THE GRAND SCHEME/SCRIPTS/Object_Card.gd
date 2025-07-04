@tool
class_name ObjectCard extends BaseCard

@export var is_object_evidence: bool:
	set(value):
		is_object_evidence = value
		if is_node_ready():
			_update_background()

## ID of corresponding entry in object database.
var database_id: String

var _owner: WeakRef
var _location: WeakRef

static var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data
static var _card_scene = preload("res://SCENES/Object_Card.tscn")

func get_card_type():
	return CardType.OBJECT

func _ready():
	super()
	_update_background()

func _update_background():
	$Card_Mask/Card_BG/Evidence.visible = is_object_evidence

func get_object_owner() -> NpcCard:
	return _owner.get_ref()

func set_object_owner(object_owner: NpcCard):
	_owner = weakref(object_owner)

func get_location() -> LocationCard:
	return _location.get_ref()

func set_location(location: LocationCard):
	_location = weakref(location)

static func create_card(id: String) -> ObjectCard:
	var card = _card_scene.instantiate()
	var object_info = _object_data[id]
	card.card_name = object_info["name"]
	card.description = object_info["description"]
	card.database_id = id
	return card

func save():
	var dict = super()
	dict["is_object_evidence"] = is_object_evidence
	dict["database_id"] = database_id
	# TODO: _owner and _location
	return dict

func load(dict):
	super(dict)
	is_object_evidence = dict["is_object_evidence"]
	database_id = dict["database_id"]
	# TODO: _owner and _location
