@tool
class_name AbstractCard extends BaseCard

## ID of corresponding entry in abstract database.
var database_id: String

static var _abstract_data = preload("res://JSON/INTERACTION/Abstract.json").data
static var _card_scene = preload("res://SCENES/Abstract_Card.tscn")

func get_card_type():
	return CardType.ABSTRACT

func _ready():
	super()

static func create_card(id: String) -> AbstractCard:
	var card = _card_scene.instantiate()
	var abstract_info = _abstract_data[id]
	card.card_name = abstract_info["name"]
	card.description = abstract_info["description"]
	card.database_id = id
	return card

func get_custom_class():
	return SaveLoadTools.Class.ABSTRACT_CARD

func get_json_dict():
	var dict = super()
	dict["database_id"] = database_id
	return dict

func restore(dict, catalog):
	super(dict, catalog)
	database_id = dict["database_id"]
	var abstract_info = _abstract_data[database_id]
	card_name = abstract_info["name"]
	description = abstract_info["description"]

static func allocate() -> Object:
	return _card_scene.instantiate()
