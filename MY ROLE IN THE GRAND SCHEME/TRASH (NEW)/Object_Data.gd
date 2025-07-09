class_name ObjectData extends ExtraCardData

var object_id: String

static var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data
static var _card_scene = preload("res://TRASH (NEW)/Old_Card.tscn")

var _owner: WeakRef
var _location: WeakRef

func _init(id: String):
	object_id = id

func get_owner() -> OldCard:
	return _owner.get_ref()

func set_owner(owner: OldCard):
	_owner = weakref(owner)

func get_location() -> OldCard:
	return _location.get_ref()

func set_location(location: OldCard):
	_location = weakref(location)

static func create_card(id: String) -> OldCard:
	var card = _card_scene.instantiate()
	card.card_type = OldCard.CardType.OBJECT
	var obj_info = _object_data[id]
	card.card_name = obj_info["name"]
	card.description = obj_info["description"]
	card.extra_data = ObjectData.new(id)
	return card
