extends Node2D

signal done

var _current_card: Card
var _confirmed: bool

@onready var _description: RichTextLabel = $Bottom_Left_Info_Long/Scroll_Interaction/Description

func _ready():
	$Buttons.ok.connect(_on_ok_pressed)
	$Buttons.cancel.connect(_on_cancel_pressed)

func start(mastery: Array[Card], pool: Array[Card]):
	for card in mastery:
		$Mastery_Cards.add_child(card)
	for card in pool:
		$Pool_Cards.add_child(card)
	Globals.mouse_entered_card.connect(_on_card_entered)
	Globals.mouse_exited_card.connect(_on_card_exited)

func _reset():
	Globals.mouse_entered_card.disconnect(_on_card_entered)
	Globals.mouse_exited_card.disconnect(_on_card_exited)
	_current_card = null
	for card in $Mastery_Cards.get_children():
		$Mastery_Cards.remove_child(card)
	for card in $Pool_Cards.get_children():
		$Pool_Cards.remove_child(card)

func _on_card_entered(card: Card):
	if _current_card:
		_current_card.set_highlighted(false)
	_current_card = card
	if _current_card:
		_current_card.set_highlighted(true)
		_description.text = _current_card.get_info()
	else:
		_description.text = ""

func _on_card_exited(card: Card):
	if _current_card == card:
		_current_card.set_highlighted(false)
		_description.text = ""
		_current_card = null

func get_confirmed() -> bool:
	return _confirmed

func _on_ok_pressed():
	_confirmed = true
	_reset()
	done.emit()

func _on_cancel_pressed():
	_confirmed = false
	_reset()
	done.emit()
