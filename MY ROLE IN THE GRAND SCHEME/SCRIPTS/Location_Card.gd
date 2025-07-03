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
		_update_background()

var location_id: String
var _inhabitants: Array[WeakRef]

static var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
static var _card_scene = preload("res://SCENES/Location_Card.tscn")

func _init():
	card_type = CardType.LOCATION

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
	card.location_id = id
	return card
