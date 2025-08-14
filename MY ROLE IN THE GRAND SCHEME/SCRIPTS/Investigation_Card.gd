@tool
class_name InvestigationCard extends Card

enum InvestigationType {
	NORMAL,
	SPECIAL,
	BREAK_IN
}

@export var investigation_type: InvestigationType = InvestigationType.NORMAL:
	set(value):
		investigation_type = value
		if is_node_ready():
			_update_background()

## ID of corresponding entry in investigation database.
var database_id: String

static var _investigation_data = preload("res://JSON/INTERACTION/Investigation.json").data
static var _card_scene = preload("res://SCENES/Investigation_Card.tscn")

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func get_card_type():
	return CardType.INVESTIGATION

func _ready():
	super()
	_update_background()

func _update_background():
		$Card_Mask/Card_BG/Card_Color/Investigation/Special.visible = (investigation_type == InvestigationType.SPECIAL)
		$Card_Mask/Card_BG/Card_Color/Investigation/Break_In.visible = (investigation_type == InvestigationType.BREAK_IN)

static func create_card(id: String) -> InvestigationCard:
	var card = _card_scene.instantiate()
	var investigation_info = _investigation_data[id]
	card.card_name = investigation_info["name"]
	card.description = investigation_info["description"]
	match investigation_info["type"]:
		"Investigation SPECIAL":
			card.investigation_type = InvestigationType.SPECIAL
		"Investigation BREAK-IN":
			card.investigation_type = InvestigationType.BREAK_IN
	card.database_id = id
	return card

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.INVESTIGATION_CARD

#
# For save/load.
#
func get_unique_id():
	return "inv%d" % _unique_id

#
# For save/load.
#
func get_json_dict():
	var dict = super()
	dict["investigation_type"] = investigation_type
	dict["database_id"] = database_id
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	investigation_type = dict["investigation_type"]
	database_id = dict["database_id"]
	var investigation_info = _investigation_data[database_id]
	card_name = investigation_info["name"]
	description = investigation_info["description"]

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
