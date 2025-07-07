class_name Player extends RefCounted

var player_name: String
var job_id: String
var job_name: String
var job_bonus_malus: Dictionary
var sex: float
var physical: int: set = set_physical, get = get_physical
var mental: int: set = set_mental, get = get_mental
var health: int: set = set_health, get = get_health
var max_health: int
var emotion: int: set = set_emotion, get = get_emotion
var addiction: int: set = set_addiction, get = get_addiction
var wanted: int: set = set_wanted, get = get_wanted
var paranoia: int
var money: int: set = set_money, get = get_money
var drugs: int: set = set_drugs, get = get_drugs

signal physical_changed
signal mental_changed
signal health_changed
signal emotion_changed
signal addiction_changed
signal wanted_changed
signal money_changed
signal drugs_changed
signal debts_changed

var _abstract_cards = preload("res://JSON/INTERACTION/Abstract.json").data
var _combat_cards = preload("res://JSON/INTERACTION/Combat.json").data
var _dialogue_cards = preload("res://JSON/INTERACTION/Dialogue.json").data
var _investigation_cards = preload("res://JSON/INTERACTION/Investigation.json").data

var _debts: Array[int]
var _cards: Array[BaseCard]
var _signal_pause: int = 0
var _sleep_bonus_malus: int = 0

func reset():
	_signal_pause += 1
	player_name = ""
	job_id = ""
	job_name = ""
	job_bonus_malus = {}
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
	drugs = 0
	_debts.clear()
	_cards.clear()
	_sleep_bonus_malus = 0
	_signal_pause -= 1

func start_game():
	_signal_pause += 1

	physical += job_bonus_malus.get("PHY", 0)
	mental += job_bonus_malus.get("MEN", 0)
	max_health += job_bonus_malus.get("HEA", 0)
	health = max_health
	emotion = 0
	addiction = 0
	wanted = 0
	paranoia = 0
	money = 300 + job_bonus_malus.get("money", 0)
	drugs = 3 + job_bonus_malus.get("drugs", 0)
	_debts.clear()
	_cards.clear()
	_sleep_bonus_malus = 0

	# all players start with one card from each category

	var id
	id = _pick_random_combat_card()
	_cards.append(CombatCard.create_card(id))
	id = _pick_random_investigation_card()
	_cards.append(InvestigationCard.create_card(id))
	id = _pick_random_dialogue_card()
	_cards.append(DialogueCard.create_card(id))
	id = _pick_random_abstract_card()
	_cards.append(AbstractCard.create_card(id))

	# some players get bonus cards

	var init_card_count = _cards.size() + job_bonus_malus.get("cards", 0)
	while _cards.size() < init_card_count:
		match randi() % 4:
			0:
				id = _pick_random_combat_card()
				_cards.append(CombatCard.create_card(id))
			1:
				id = _pick_random_investigation_card()
				_cards.append(InvestigationCard.create_card(id))
			2:
				id = _pick_random_dialogue_card()
				_cards.append(DialogueCard.create_card(id))
			3:
				id = _pick_random_abstract_card()
				_cards.append(AbstractCard.create_card(id))

	print("player: ", player_name)
	print("sex: ", sex)
	print("job: ", job_name)
	print("PHY: ", physical)
	print("MEN: ", mental)
	print("HEA: ", health)
	print("dough: %d Dø" % money)
	print("drugs: %d doses" % drugs)
	for card in _cards:
		print("card: %s (%s)" % [card.card_name, card.database_id])

	_signal_pause -= 1

func _pick_random_abstract_card() -> String:
	var id = _abstract_cards.keys().pick_random()
	while _have_card_already(BaseCard.CardType.ABSTRACT, id):
		id = _abstract_cards.keys().pick_random()
	return id

func _pick_random_dialogue_card() -> String:
	var id = _dialogue_cards.keys().pick_random()
	while _have_card_already(BaseCard.CardType.DIALOGUE, id):
		id = _dialogue_cards.keys().pick_random()
	return id

func _pick_random_combat_card() -> String:
	var id = _combat_cards.keys().pick_random()
	while (_combat_cards[id]["type"] != "Combat"
		   or _have_card_already(BaseCard.CardType.COMBAT, id)):
		id = _combat_cards.keys().pick_random()
	return id

func _pick_random_investigation_card() -> String:
	var id = _investigation_cards.keys().pick_random()
	while (_investigation_cards[id]["type"] != "Investigation"
		   or _have_card_already(BaseCard.CardType.INVESTIGATION, id)):
		id = _investigation_cards.keys().pick_random()
	return id

func _have_card_already(type: BaseCard.CardType, id: String):
	for card in _cards:
		if card.get_card_type() == type and card.database_id == id:
			return true
	return false

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
	hea = mini(hea, max_health)
	if health != hea:
		health = hea
		if _signal_pause == 0:
			health_changed.emit()

func get_health() -> int:
	return health

func set_emotion(emo: int):
	emo = clampi(emo, -3, 3)
	if emotion != emo:
		emotion = emo
		if _signal_pause == 0:
			emotion_changed.emit()

func get_emotion() -> int:
	return emotion

func set_addiction(add: int):
	add = clampi(add, -3, 3)
	if addiction != add:
		addiction = add
		if _signal_pause == 0:
			addiction_changed.emit()

func get_addiction() -> int:
	return addiction

func set_wanted(wan: int):
	wan = clampi(wan, 0, 4)
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

func add_debt(debt: int):
	_debts.insert(0, debt)
	debts_changed.emit()

func get_debt_count() -> int:
	return _debts.size()

func get_debt(index: int) -> int:
	return _debts[index]

func set_debt(index: int, new_debt: int):
	_debts[index] = new_debt

func pay_debt(index: int):
	money -= _debts[index]
	_debts.remove_at(index)
	debts_changed.emit()

func get_debt_total() -> int:
	var total = 0
	for debt in _debts:
		total += debt
	return total

func pass_one_hour():
	if randi() % 10 == 0:
		match randi() % 3:
			0:
				physical += 1
			1:
				mental += 1
			2:
				health += 1

func _exacerbate(start_value: int, how_much: int) -> int:
	if start_value < 0:
		return start_value - how_much
	elif start_value > 0:
		return start_value + how_much
	elif randi() & 1:
		return how_much
	else:
		return -how_much

func _calm(start_value: int, how_much: int) -> int:
	if start_value == 0:
		return start_value
	elif start_value < 0:
		return mini(0, start_value + how_much)
	else:
		return maxi(0, start_value - how_much)

func sleep(hours: int):
	var dream_health_bonus = 0
	var dream = randf()

	if dream < 0.125:
		dream_health_bonus = 1
		Globals.dialog_overlay.show_dream_message(false)
	elif dream < 0.25:
		dream_health_bonus = -1
		Globals.dialog_overlay.show_dream_message(true)

	match hours:
		4:
			health += dream_health_bonus
			emotion = _exacerbate(emotion, 1)
			addiction = _exacerbate(addiction, 1)
			_sleep_bonus_malus = -2
		5:
			health += dream_health_bonus
			emotion = _exacerbate(emotion, 1)
			_sleep_bonus_malus = -1
		6:
			health += dream_health_bonus
			_sleep_bonus_malus = -1
		7:
			health += 1 + dream_health_bonus
			_sleep_bonus_malus = 0
		8:
			health += 1 + dream_health_bonus
			emotion = _calm(emotion, 1)
			_sleep_bonus_malus = 0
		9:
			health += 1 + dream_health_bonus
			emotion = _calm(emotion, 2)
			_sleep_bonus_malus = 0
		10:
			health += 2 + dream_health_bonus
			emotion = _calm(emotion, 1)
			_sleep_bonus_malus = 1
		11:
			health += 2 + dream_health_bonus
			emotion = _calm(emotion, 2)
			_sleep_bonus_malus = 1
		12:
			health += 3 + dream_health_bonus
			emotion = _calm(emotion, 1)
			_sleep_bonus_malus = 2


func get_custom_class():
	return SaveLoadTools.Class.PLAYER

func get_referenced_objects():
	return _cards

func get_json_dict():
	var dict = {
		"player_name": player_name,
		"job_id": job_id,
		"job_name": job_name,
		"job_bonus_malus": job_bonus_malus,
		"sex": sex,
		"physical": physical,
		"mental": mental,
		"health": health,
		"max_health": max_health,
		"emotion": emotion,
		"addiction": addiction,
		"wanted": wanted,
		"paranoia": paranoia,
		"money": money,
		"drugs": drugs,
		"debts": _debts,
		"sleep_bonus_malus": _sleep_bonus_malus
	}
	var card_refs = []
	for card in _cards:
		card_refs.append(SaveLoadTools.get_object_id(card))
	dict["cards"] = card_refs
	return dict

func _restore_from_json_dict(dict):
	player_name = dict.player_name
	job_id = dict.job_id
	job_name = dict.job_name
	job_bonus_malus = dict.job_bonus_malus
	sex = dict.sex
	physical = dict.physical
	mental = dict.mental
	max_health = dict.max_health
	health = dict.health
	emotion = dict.emotion
	addiction = dict.addiction
	wanted = dict.wanted
	paranoia = dict.paranoia
	money = dict.money
	drugs = dict.drugs
	_debts.assign(dict.debts)
	_sleep_bonus_malus = dict.sleep_bonus_malus

func set_referenced_objects(dict, catalog):
	for card_ref in dict.cards:
		_cards.append(catalog[card_ref])

static func restore(dict) -> Object:
	var player = Player.new()
	player._restore_from_json_dict(dict)
	return player
