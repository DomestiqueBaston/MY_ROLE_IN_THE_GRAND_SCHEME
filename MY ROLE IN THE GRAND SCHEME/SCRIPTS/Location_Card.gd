@tool
class_name LocationCard extends BaseCard

enum LocationStatus {
	NONE,
	CLOSED,
	CRIME_SCENE
}

@export var location_status: LocationStatus:
	set(value):
		location_status = value
		if is_node_ready():
			_update_background()

## ID of corresponding entry in location database.
var database_id: String

var _inhabitants: Array[WeakRef]

static var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
static var _card_scene = preload("res://SCENES/Location_Card.tscn")

func get_card_type():
	return CardType.LOCATION

func _ready():
	super()
	_update_background()

func _update_background():
	$Card_Mask/Card_BG/Closed_Status.visible = (location_status == LocationStatus.CLOSED)
	$Card_Mask/Card_BG/Crime_Scene_Status.visible = (location_status == LocationStatus.CRIME_SCENE)

func add_inhabitant(inhabitant: NpcCard):
	_inhabitants.append(weakref(inhabitant))

func get_inhabitant_count() -> int:
	return _inhabitants.size()

func get_inhabitant(index: int) -> NpcCard:
	return _inhabitants[index].get_ref()

func get_inhabitants() -> Array[NpcCard]:
	var ret: Array[NpcCard]
	for ref in _inhabitants:
		ret.append(ref.get_ref())
	return ret

static func create_card(id: String) -> LocationCard:
	var card = _card_scene.instantiate()
	var location_info = _location_data[id]
	card.card_name = location_info["name"]
	card.description = location_info["description"]
	card.database_id = id
	return card

func get_custom_class():
	return SaveLoadTools.Class.LOCATION_CARD

func get_referenced_objects():
	var refs = []
	for card in _inhabitants:
		refs.append(card.get_ref())
	return refs

func get_json_dict():
	var dict = super()
	dict["location_status"] = location_status
	dict["database_id"] = database_id
	if _inhabitants:
		var refs = []
		for card in _inhabitants:
			refs.append(SaveLoadTools.get_object_id(card.get_ref()))
		dict["inhabitants"] = refs
	return dict

func restore(dict, catalog):
	super(dict, catalog)
	location_status = dict["location_status"]
	database_id = dict["database_id"]
	if "inhabitants" in dict:
		for card in dict.inhabitants:
			_inhabitants.append(weakref(catalog[card]))

static func allocate() -> Object:
	return _card_scene.instantiate()
