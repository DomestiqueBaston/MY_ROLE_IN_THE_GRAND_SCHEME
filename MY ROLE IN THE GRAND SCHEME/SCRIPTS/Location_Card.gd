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
			_update_appearance()

@export var crime_scene_color: Color = Color("#ff5757"):
	set(value):
		crime_scene_color = value
		if is_node_ready() and location_status == LocationStatus.CRIME_SCENE:
			_update_appearance()

## ID of corresponding entry in location database.
var database_id: String

static var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
static var _card_scene = preload("res://SCENES/Location_Card.tscn")

func get_card_type():
	return CardType.LOCATION

func _ready():
	super()
	_update_appearance()

func _update_appearance():
	$Card_Mask/Card_BG/Closed_Status.visible = (location_status == LocationStatus.CLOSED)
	$Card_Mask/Card_BG/Crime_Scene_Status.visible = (location_status == LocationStatus.CRIME_SCENE)

	if location_status == LocationStatus.CRIME_SCENE:
		$Card_Mask/Card_BG/Card_Outlines.self_modulate = crime_scene_color
		$Card_Drag.modulate = crime_scene_color
	else:
		$Card_Mask/Card_BG/Card_Outlines.self_modulate = Color.WHITE
		$Card_Drag.modulate = Color.WHITE

	if not Engine.is_editor_hint():
		tooltip = card_name
		if location_status != LocationStatus.NONE:
			tooltip += "\n" + LocationStatus.keys()[location_status].capitalize()

func get_display_name() -> String:
	var inhabitants = get_connections(Link.Type.HOME)
	match inhabitants.size():
		1:
			return "%s's %s" % [inhabitants[0].first_name, card_name]
		2:
			var family_name = inhabitants[0].last_name
			if not family_name.ends_with("s"):
				family_name += "s"
			return "%s' %s" % [family_name, card_name]
		_:
			return card_name

static func create_card(id: String) -> LocationCard:
	var card = _card_scene.instantiate()
	var location_info = _location_data[id]
	card.card_name = location_info.name
	card.description = location_info.description
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
func get_json_dict():
	var dict = super()
	if location_status != LocationStatus.NONE:
		dict["location_status"] = location_status
	dict["database_id"] = database_id
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	location_status = dict.get("location_status", LocationStatus.NONE)
	database_id = dict["database_id"]
	var location_info = _location_data[database_id]
	card_name = location_info.name
	description = location_info.description

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
