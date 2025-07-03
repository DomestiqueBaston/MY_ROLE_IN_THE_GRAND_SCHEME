class_name LocationData extends ExtraCardData

var location_id: String

static var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
static var _card_scene = preload("res://SCENES/Old_Card.tscn")

var _inhabitants: Array[WeakRef]

func _init(id: String):
	location_id = id

func add_inhabitant(inhabitant: OldCard):
	_inhabitants.append(weakref(inhabitant))

func get_inhabitant_count() -> int:
	return _inhabitants.size()

func get_inhabitant(index: int) -> OldCard:
	return _inhabitants[index].get_ref()

func get_inhabitants() -> Array[OldCard]:
	var ret: Array[OldCard]
	for ref in _inhabitants:
		ret.append(ref.get_ref())
	return ret

static func create_card(id: String) -> OldCard:
	var card: OldCard = _card_scene.instantiate()
	card.card_type = OldCard.CardType.LOCATION
	var loc_info = _location_data[id]
	card.card_name = loc_info["name"]
	card.description = loc_info["description"]
	card.extra_data = LocationData.new(id)
	return card
