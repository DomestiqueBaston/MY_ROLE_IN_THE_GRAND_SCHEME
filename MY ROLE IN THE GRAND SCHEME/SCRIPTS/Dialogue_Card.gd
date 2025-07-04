@tool
class_name DialogueCard extends BaseCard

## ID of corresponding entry in dialogue database.
var database_id: String

static var _dialogue_data = preload("res://JSON/INTERACTION/Dialogue.json").data
static var _card_scene = preload("res://SCENES/Dialogue_Card.tscn")

func get_card_type():
	return CardType.DIALOGUE

func _ready():
	super()

static func create_card(id: String) -> DialogueCard:
	var card = _card_scene.instantiate()
	var dialogue_info = _dialogue_data[id]
	card.card_name = dialogue_info["name"]
	card.description = dialogue_info["description"]
	card.database_id = id
	return card
