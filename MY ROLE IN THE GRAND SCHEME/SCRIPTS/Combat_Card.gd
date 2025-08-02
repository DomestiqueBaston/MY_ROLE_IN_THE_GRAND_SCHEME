@tool
class_name CombatCard extends Card

enum CombatType {
	NONE,
	SPECIAL,
	RUN_AWAY
}

@export var combat_type: CombatType:
	set(value):
		combat_type = value
		if is_node_ready():
			_update_background()

## ID of corresponding entry in combat database.
var database_id: String

static var _combat_data = preload("res://JSON/INTERACTION/Combat.json").data
static var _card_scene = preload("res://SCENES/Combat_Card.tscn")

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func get_card_type():
	return CardType.COMBAT

func _ready():
	super()
	_update_background()

func _update_background():
	$Card_Mask/Card_BG/Card_Color/Combat/Special.visible = (combat_type == CombatType.SPECIAL)
	$Card_Mask/Card_BG/Card_Color/Combat/Run_Away.visible = (combat_type == CombatType.RUN_AWAY)

static func create_card(id: String) -> CombatCard:
	var card = _card_scene.instantiate()
	var combat_info = _combat_data[id]
	card.card_name = combat_info["name"]
	card.description = combat_info["description"]
	card.database_id = id
	return card

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.COMBAT_CARD

#
# For save/load.
#
func get_unique_id():
	return "com%d" % _unique_id

#
# For save/load.
#
func get_json_dict():
	var dict = super()
	dict["combat_type"] = combat_type
	dict["database_id"] = database_id
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	combat_type = dict["combat_type"]
	database_id = dict["database_id"]
	var combat_info = _combat_data[database_id]
	card_name = combat_info["name"]
	description = combat_info["description"]

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
