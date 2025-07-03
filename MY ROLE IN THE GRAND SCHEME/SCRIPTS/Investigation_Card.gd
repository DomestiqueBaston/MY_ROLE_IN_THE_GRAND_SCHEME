@tool
class_name InvestigationCard extends BaseCard

enum InvestigationType {
	NONE,
	SPECIAL,
	BREAK_IN
}

@export var investigation_type: InvestigationType:
	set(value):
		investigation_type = value
		_update_background()

var investigation_id: String

static var _investigation_data = preload("res://JSON/INTERACTION/Investigation.json").data
static var _card_scene = preload("res://SCENES/Investigation_Card.tscn")

func _init():
	card_type = CardType.INVESTIGATION

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
	card.investigation_id = id
	return card
