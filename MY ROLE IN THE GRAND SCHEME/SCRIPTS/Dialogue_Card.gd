@tool
class_name DialogueCard extends Card

## ID of corresponding entry in dialogue database.
var database_id: String

static var _dialogue_data = preload("res://JSON/INTERACTION/Dialogue.json").data
static var _card_scene = preload("res://SCENES/Dialogue_Card.tscn")

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func get_card_type():
	return CardType.DIALOGUE

func get_info() -> String:
	return _dialogue_data[database_id].get("info", "")

func _ready():
	super()

static func create_card(id: String) -> DialogueCard:
	var card = _card_scene.instantiate()
	var dialogue_info = _dialogue_data[id]
	card.card_name = dialogue_info["name"]
	card.description = dialogue_info["description"]
	card.database_id = id
	return card

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.DIALOGUE_CARD

#
# For save/load.
#
func get_unique_id():
	return "dia%d" % _unique_id

#
# For save/load.
#
func get_json_dict():
	var dict = super()
	dict["database_id"] = database_id
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	database_id = dict["database_id"]
	var dialogue_info = _dialogue_data[database_id]
	card_name = dialogue_info["name"]
	description = dialogue_info["description"]

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
