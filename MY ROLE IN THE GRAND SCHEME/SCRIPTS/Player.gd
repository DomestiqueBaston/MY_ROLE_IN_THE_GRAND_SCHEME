extends Node

@export var player_name: String
@export var background: Dictionary
@export_range(0.0, 1.0) var sex: float
@export var physical: int
@export var mental: int
@export var max_health: int
@export var health: int
@export_range(-3, 3) var emotion: int
@export_range(-3, 3) var addiction: int
@export_range(0, 4) var wanted: int
@export var paranoia: int
@export var money: int
@export var debts: Array[int]
@export var drugs: int
@export var cards: Array[Dictionary]

@onready var _abstract_cards = preload("res://JSON/INTERACTION/Abstract.json").data
@onready var _combat_cards = preload("res://JSON/INTERACTION/Combat.json").data
@onready var _dialogue_cards = preload("res://JSON/INTERACTION/Dialogue.json").data
@onready var _investigation_cards = preload("res://JSON/INTERACTION/Investigation.json").data

func reset():
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

func start_game():
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
