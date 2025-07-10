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

## NPCs that are connected to the location: it's their home, their place of
## work, their hangout or their hideout.
var _npcs: Array[WeakRef]

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

func add_npc(npc: NpcCard):
	for card in _npcs:
		if card.get_ref() == npc:
			return
	_npcs.append(weakref(npc))

func get_npc_count() -> int:
	return _npcs.size()

func get_npc(index: int) -> NpcCard:
	return _npcs[index].get_ref()

func get_npcs() -> Array[NpcCard]:
	var ret: Array[NpcCard]
	for ref in _npcs:
		ret.append(ref.get_ref())
	return ret

static func create_card(id: String) -> LocationCard:
	var card = _card_scene.instantiate()
	var location_info = _location_data[id]
	card.card_name = location_info["name"]
	card.description = location_info["description"]
	card.database_id = id
	return card

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.LOCATION_CARD

#
# For save/load.
#
func get_referenced_objects():
	var refs = []
	for card in _npcs:
		refs.append(card.get_ref())
	return refs

#
# For save/load.
#
func get_json_dict():
	var dict = super()
	if location_status != LocationStatus.NONE:
		dict["location_status"] = location_status
	dict["database_id"] = database_id
	if _npcs:
		var refs = []
		for card in _npcs:
			refs.append(SaveLoadTools.get_object_id(card.get_ref()))
		dict["npcs"] = refs
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	location_status = dict.get("location_status", LocationStatus.NONE)
	database_id = dict["database_id"]
	var location_info = _location_data[database_id]
	card_name = location_info["name"]
	description = location_info["description"]
	if "npcs" in dict:
		for card in dict.npcs:
			_npcs.append(weakref(catalog[card]))

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
