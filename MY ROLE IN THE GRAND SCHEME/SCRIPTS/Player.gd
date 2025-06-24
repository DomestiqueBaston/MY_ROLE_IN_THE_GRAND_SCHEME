extends Node

@export var player_name: String
@export var background: Dictionary
@export_range(0.0, 1.0) var sex: float
@export var physical: int:
	set = set_physical, get = get_physical
@export var mental: int:
	set = set_mental, get = get_mental
@export var health: int:
	set = set_health, get = get_health
@export var max_health: int
@export_range(-3, 3) var emotion: int:
	set = set_emotion, get = get_emotion
@export_range(-3, 3) var addiction: int
@export_range(0, 4) var wanted: int
@export var paranoia: int
@export var money: int:
	set = set_money, get = get_money
@export var debts: Array[int]
@export var drugs: int:
	set = set_drugs, get = get_drugs
@export var cards: Array[Dictionary]

signal physical_changed
signal mental_changed
signal health_changed
signal emotion_changed
signal addiction_changed
signal wanted_changed
signal money_changed
signal drugs_changed

@onready var _abstract_cards = preload("res://JSON/INTERACTION/Abstract.json").data
@onready var _combat_cards = preload("res://JSON/INTERACTION/Combat.json").data
@onready var _dialogue_cards = preload("res://JSON/INTERACTION/Dialogue.json").data
@onready var _investigation_cards = preload("res://JSON/INTERACTION/Investigation.json").data

var _signal_pause: int = 0

func reset():
	_signal_pause += 1
	player_name = ""
	background = {}
	sex = 0
	physical = 0
	mental = 0
	max_health = 0
	health = 0
	emotion = 0
	addiction = 0
	wanted = 0
	paranoia = 0
	money = 0
	debts.clear()
	drugs = 0
	cards.clear()
	_signal_pause -= 1

func start_game():
	_signal_pause += 1

	var bonus_malus = background.get("bonus_malus", {})
	physical += bonus_malus.get("PHY", 0)
	mental += bonus_malus.get("MEN", 0)
	max_health += bonus_malus.get("HEA", 0)
	health = max_health
	emotion = 0
	addiction = 0
	wanted = 0
	paranoia = 0
	money = 300 + bonus_malus.get("money", 0)
	debts.clear()
	drugs = 3 + bonus_malus.get("drugs", 0)
	cards.clear()

	var card_lists = [
		_dialogue_cards.get("dialogue", []),
		_combat_cards.get("combat", []),
		_investigation_cards.get("investigation", []),
		_abstract_cards.get("abstract", [])
	]

	# all players start with one card from each category

	for card_list in card_lists:
		if not card_list.is_empty():
			cards.append(card_list[randi_range(0, card_list.size() - 1)])

	# some players get bonus cards

	var init_card_count = cards.size() + bonus_malus.get("cards", 0)
	while cards.size() < init_card_count:
		var card_list = card_lists[randi_range(0, card_lists.size() - 1)]
		if not card_list.is_empty():
			var card = card_list[randi_range(0, card_list.size() - 1)]
			if not card in cards:
				cards.append(card)

	print("player: ", player_name)
	print("sex: ", sex)
	print("profession: ", background.get("profession"))
	print("PHY: ", physical)
	print("MEN: ", mental)
	print("HEA: ", health)
	print("dough: %d Dø" % money)
	print("drugs: %d doses" % drugs)
	for card in cards:
		print("%s card: %s (%s)" % [card.type, card.name, card.id])

	_signal_pause -= 1

func set_physical(phy: int):
	if physical != phy:
		physical = phy
		if _signal_pause == 0:
			physical_changed.emit()

func get_physical() -> int:
	return physical

func set_mental(men: int):
	if mental != men:
		mental = men
		if _signal_pause == 0:
			mental_changed.emit()

func get_mental() -> int:
	return mental

func set_health(hea: int):
	if health != hea:
		health = hea
		if _signal_pause == 0:
			health_changed.emit()

func get_health() -> int:
	return health

func set_emotion(emo: int):
	if emotion != emo:
		emotion = emo
		if _signal_pause == 0:
			emotion_changed.emit()

func get_emotion() -> int:
	return emotion

func set_addiction(add: int):
	if addiction != add:
		addiction = add
		if _signal_pause == 0:
			addiction_changed.emit()

func get_addiction() -> int:
	return addiction

func set_wanted(wan: int):
	if wanted != wan:
		wanted = wan
		if _signal_pause == 0:
			wanted_changed.emit()

func get_wanted() -> int:
	return wanted

func set_money(dough: int):
	if money != dough:
		money = dough
		if _signal_pause == 0:
			money_changed.emit()

func get_money() -> int:
	return money

func set_drugs(doses: int):
	if drugs != doses:
		drugs = doses
		if _signal_pause == 0:
			drugs_changed.emit()

func get_drugs() -> int:
	return drugs
