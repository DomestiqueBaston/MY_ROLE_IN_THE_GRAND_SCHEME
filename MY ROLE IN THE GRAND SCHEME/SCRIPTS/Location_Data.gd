class_name LocationData extends ExtraCardData

var location_id: String

static var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
static var _card_scene = preload("res://SCENES/Card.tscn")

var _inhabitants: Array[WeakRef]

func _init(id: String):
	location_id = id

func add_inhabitant(inhabitant: Card):
	_inhabitants.append(weakref(inhabitant))

func get_inhabitant_count() -> int:
	return _inhabitants.size()

func get_inhabitant(index: int) -> Card:
	return _inhabitants[index].get_ref()

func get_inhabitants() -> Array[Card]:
	var ret: Array[Card]
	for ref in _inhabitants:
		ret.append(ref.get_ref())
	return ret

static func create_card(id: String) -> Card:
	var card: Card = _card_scene.instantiate()
	card.card_type = Card.CardType.LOCATION
	var loc_info = _location_data[id]
	card.card_name = loc_info["name"]
	card.description = loc_info["description"]
	card.extra_data = LocationData.new(id)
	return card
