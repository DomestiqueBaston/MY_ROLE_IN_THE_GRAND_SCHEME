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
var drugs_taken_today: int
var has_search_warrant: bool

var _abstract_cards = preload("res://JSON/INTERACTION/Abstract.json").data
var _combat_cards = preload("res://JSON/INTERACTION/Combat.json").data
var _dialogue_cards = preload("res://JSON/INTERACTION/Dialogue.json").data
var _investigation_cards = preload("res://JSON/INTERACTION/Investigation.json").data

var _debts: Array[int]
var _mastery_cards: Array[Card]
var _fallback_cards: Array[Card]
var _signal_pause: int = 0
var _last_wake_time: int
var _sleep_bonus_malus: int

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
	drugs_taken_today = 0
	has_search_warrant = false
	_debts.clear()
	clear_mastery_cards()
	clear_fallback_cards()
	_last_wake_time = 0
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
	drugs_taken_today = 0
	has_search_warrant = false
	_debts.clear()
	clear_mastery_cards()
	clear_fallback_cards()
	_last_wake_time = GameState.get_time()
	_sleep_bonus_malus = 0

	# all players start with one card from each category

	var id
	id = _pick_random_combat_card()
	_mastery_cards.append(CombatCard.create_card(id))
	id = _pick_random_investigation_card()
	_mastery_cards.append(InvestigationCard.create_card(id))
	id = _pick_random_dialogue_card()
	_mastery_cards.append(DialogueCard.create_card(id))
	id = _pick_random_abstract_card()
	_mastery_cards.append(AbstractCard.create_card(id))

	# some players get bonus cards

	var init_card_count = _mastery_cards.size() + job_bonus_malus.get("cards", 0)
	while _mastery_cards.size() < init_card_count:
		match randi() % 4:
			0:
				id = _pick_random_combat_card()
				_mastery_cards.append(CombatCard.create_card(id))
			1:
				id = _pick_random_investigation_card()
				_mastery_cards.append(InvestigationCard.create_card(id))
			2:
				id = _pick_random_dialogue_card()
				_mastery_cards.append(DialogueCard.create_card(id))
			3:
				id = _pick_random_abstract_card()
				_mastery_cards.append(AbstractCard.create_card(id))

	_signal_pause -= 1

func _pick_random_abstract_card() -> String:
	var id = _abstract_cards.keys().pick_random()
	while _have_card_already(Card.CardType.ABSTRACT, id):
		id = _abstract_cards.keys().pick_random()
	return id

func _pick_random_dialogue_card() -> String:
	var id = _dialogue_cards.keys().pick_random()
	while _have_card_already(Card.CardType.DIALOGUE, id):
		id = _dialogue_cards.keys().pick_random()
	return id

func _pick_random_combat_card(
	is_normal_ok: bool = true,
	is_special_ok: bool = false,
	is_run_away_ok: bool = false) -> String:
	var id = ""
	var ok = false
	while not ok:
		id = _combat_cards.keys().pick_random()
		match _combat_cards[id]["type"]:
			"Combat":
				ok = is_normal_ok
			"Combat SPECIAL":
				ok = is_special_ok
			"Combat RUN-AWAY":
				ok = is_run_away_ok
		ok = ok and not _have_card_already(Card.CardType.COMBAT, id)
	return id

func _pick_random_investigation_card(
	is_normal_ok: bool = true,
	is_special_ok: bool = false,
	is_break_in_ok: bool = false) -> String:
	var id = ""
	var ok = false
	while not ok:
		id = _investigation_cards.keys().pick_random()
		match _investigation_cards[id]["type"]:
			"Investigation":
				ok = is_normal_ok
			"Investigation SPECIAL":
				ok = is_special_ok
			"Investigation BREAK-IN":
				ok = is_break_in_ok
		ok = ok and not _have_card_already(Card.CardType.INVESTIGATION, id)
	return id

func _have_card_already(type: Card.CardType, id: String):
	for card_list in [_mastery_cards, _fallback_cards]:
		for card in card_list:
			if card.get_card_type() == type and card.database_id == id:
				return true
	return false

func set_physical(phy: int):
	if physical != phy:
		physical = phy
		if _signal_pause == 0:
			GameState.physical_changed.emit()

func get_physical() -> int:
	return physical

func set_mental(men: int):
	if mental != men:
		mental = men
		if _signal_pause == 0:
			GameState.mental_changed.emit()

func get_mental() -> int:
	return mental

func set_health(hea: int):
	hea = mini(hea, max_health)
	if health != hea:
		health = hea
		if _signal_pause == 0:
			GameState.health_changed.emit()

##
## Checks the player's health, emotion and addiction levels, and returns false
## if he has died. Note that if his emotion level reaches -5 or 5, that has
## negative consequences for his addiction level. And if his addiction level
## reaches -5 or 5, a message is displayed, indicating whether or not he has
## survived. As a result, this function is a coroutine to be awaited.
##
func test_health() -> bool:
	if health <= 0:
		return false

	while emotion <= -5 or emotion >= 5:
		addiction += 1 if addiction > 0 else -1
		emotion -= signi(emotion)

	if addiction <= -5 or addiction >= 5:
		var die = (health == 1 or randi_range(1, 10) > health)
		await Globals.dialog_overlay.show_addiction_message(die)
		if die:
			return false
		addiction = 4 * signi(addiction)

	return true

func get_health() -> int:
	return health

func set_emotion(emo: int):
	emo = clampi(emo, -5, 5)
	if emotion != emo:
		emotion = emo
		if _signal_pause == 0:
			GameState.emotion_changed.emit()

##
## Improves the player's emotional state by at most how_much, meaning Emo
## increases if it is negative or decreases if it is positive.
##
func improve_emotion(how_much: int):
	set_emotion(calm(emotion, how_much))

func get_emotion() -> int:
	return emotion

func set_addiction(add: int):
	add = clampi(add, -5, 5)
	if addiction != add:
		addiction = add
		if _signal_pause == 0:
			GameState.addiction_changed.emit()

##
## Improves the player's addiction state by at most how_much, meaning Add
## increases if it is negative or decreases if it is positive.
##
func improve_addiction(how_much: int):
	set_addiction(calm(addiction, how_much))

func get_addiction() -> int:
	return addiction

func set_wanted(wan: int):
	wan = clampi(wan, 0, 5)
	if wanted != wan:
		wanted = wan
		if _signal_pause == 0:
			GameState.wanted_changed.emit()

func get_wanted() -> int:
	return wanted

func set_money(dough: int):
	if money != dough:
		money = dough
		if _signal_pause == 0:
			GameState.money_changed.emit()

func get_money() -> int:
	return money

func set_drugs(doses: int):
	if drugs != doses:
		drugs = doses
		if _signal_pause == 0:
			GameState.drugs_changed.emit()

func get_drugs() -> int:
	return drugs

func use_drugs(doses: int):
	doses = mini(mini(doses, drugs), 2 - drugs_taken_today)
	drugs_taken_today += doses
	drugs -= doses
	addiction += doses

func add_debt(debt: int):
	_debts.insert(0, debt)
	GameState.debts_changed.emit()

func get_debt_count() -> int:
	return _debts.size()

func get_debt(index: int) -> int:
	return _debts[index]

func set_debt(index: int, new_debt: int):
	_debts[index] = new_debt

func pay_debt(index: int):
	money -= _debts[index]
	_debts.remove_at(index)
	GameState.debts_changed.emit()

func get_debt_total() -> int:
	var total = 0
	for debt in _debts:
		total += debt
	return total

##
## Returns the cards the player has in his "mastery" deck.
##
func get_mastery_cards() -> Array[Card]:
	return _mastery_cards

##
## Clears the player's "mastery" deck, deleting any cards it contains.
##
func clear_mastery_cards():
	for card in _mastery_cards:
		card.queue_free()
	_mastery_cards.clear()

##
## Removes the given card from the player's "mastery" deck, if found there, and
## deletes it. Returns true if successful, false if the card is not in the deck.
##
func remove_mastery_card(card: Card) -> bool:
	var index = _mastery_cards.find(card)
	if index < 0:
		return false
	_mastery_cards.remove_at(index)
	card.queue_free()
	return true

##
## Returns the cards the player has in his temporary "fallback" deck for
## interactions.
##
func get_fallback_cards() -> Array[Card]:
	return _fallback_cards

##
## Clears the player's "fallback" deck, deleting any cards it contains.
##
func clear_fallback_cards():
	for card in _fallback_cards:
		card.queue_free()
	_fallback_cards.clear()

##
## Picks 5 abstract and/or investigation cards at random for an investigation,
## ensuring that there are no duplicates with the player's "mastery" cards, and
## puts them in the player's "fallback" deck. Any cards already in the fallback
## deck are deleted.
##
func pick_investigation_cards():
	clear_fallback_cards()

	# 1 or 2 abstract cards

	var abstract_count = randi_range(1, 2)

	while _fallback_cards.size() < abstract_count:
		var id = _pick_random_abstract_card()
		_fallback_cards.append(AbstractCard.create_card(id))

	# 3 or 4 Investigation (at least 1) and Investigation SPECIAL cards

	var investigation_count = 0

	while _fallback_cards.size() < 5:
		var id = _pick_random_investigation_card(true, investigation_count > 0)
		var card = InvestigationCard.create_card(id)
		_fallback_cards.append(card)
		if card.investigation_type == InvestigationCard.InvestigationType.NORMAL:
			investigation_count += 1

##
## Picks 3 cards abstract and/or break-in cards at random for a break-in,
## ensuring that there are no duplicates with the player's "mastery" cards, and
## puts them in the player's "fallback" deck. Any cards already in the fallback
## deck are deleted.
##
func pick_break_in_cards():
	clear_fallback_cards()
	var roll = randi()
	for i in 3:
		if roll & (1 << i):
			var id = _pick_random_abstract_card()
			_fallback_cards.append(AbstractCard.create_card(id))
		else:
			var id = _pick_random_investigation_card(false, false, true)
			_fallback_cards.append(InvestigationCard.create_card(id))

func pass_one_hour():
	if randi() % 10 == 0:
		match randi() % 3:
			0:
				physical += 1
			1:
				mental += 1
			2:
				health += 1

##
## Given the current value of a signed attribute (emotion or addiction),
## returns a value that is worse (farther from zero) by how_much.
##
static func exacerbate(start_value: int, how_much: int = 1) -> int:
	if start_value < 0:
		return start_value - how_much
	elif start_value > 0:
		return start_value + how_much
	elif randi() & 1:
		return how_much
	else:
		return -how_much

##
## Given the current value of a signed attribute (emotion or addiction),
## returns a value that is better (closer to zero) by at most how_much.
##
static func calm(start_value: int, how_much: int = 1) -> int:
	if start_value == 0:
		return start_value
	elif start_value < 0:
		return mini(0, start_value + how_much)
	else:
		return maxi(0, start_value - how_much)

##
## Returns the number of hours since the player last slept.
##
func get_hours_awake() -> int:
	return GameState.get_time() - _last_wake_time

##
## Puts the player to sleep for a certain number of hours. His health, emotion
## and addiction characteristics are updated accordingly, and it is noted that
## he will awake the given number of hours later.
##
func sleep(hours: int):
	_last_wake_time = GameState.get_time() + hours

	var dream_health_bonus = 0
	var dream = randf()

	if dream < 0.125:
		dream_health_bonus = 1
		await Globals.dialog_overlay.show_dream_message(false)
	elif dream < 0.25:
		dream_health_bonus = -1
		await Globals.dialog_overlay.show_dream_message(true)

	match hours:
		4:
			health += dream_health_bonus
			emotion = exacerbate(emotion, 1)
			addiction = exacerbate(addiction, 1) - 1
			_sleep_bonus_malus = 2
		5:
			health += dream_health_bonus
			emotion = exacerbate(emotion, 1)
			addiction -= 1
			_sleep_bonus_malus = 1
		6:
			health += dream_health_bonus
			addiction -= 1
			_sleep_bonus_malus = 1
		7:
			health += 1 + dream_health_bonus
			addiction -= 1
			_sleep_bonus_malus = 0
		8:
			health += 1 + dream_health_bonus
			emotion = calm(emotion, 1)
			addiction -= 1
			_sleep_bonus_malus = 0
		9:
			health += 1 + dream_health_bonus
			emotion = calm(emotion, 2)
			addiction -= 1
			_sleep_bonus_malus = 0
		10:
			health += 2 + dream_health_bonus
			emotion = calm(emotion, 1)
			addiction -= 1
			_sleep_bonus_malus = -1
		11:
			health += 2 + dream_health_bonus
			emotion = calm(emotion, 2)
			addiction -= 1
			_sleep_bonus_malus = -1
		12:
			health += 3 + dream_health_bonus
			emotion = calm(emotion, 1)
			addiction -= 1
			_sleep_bonus_malus = -2

##
## Call this at the start of each new day, to tell the player he hasn't taken
## any drugs yet today, and to reduce his "wanted" level by 1.
##
func new_day():
	drugs_taken_today = 0
	if wanted > 0:
		wanted -= 1

##
## Returns a bonus/malus to be added to dice rolls, depending on the player's
## emotion, addiction and wanted levels, how long it has been since he slept,
## how well he slept last time, and the number of unpaid bills he has. A
## negative number is a bonus, a positive number is a malus.
##
func get_bonus_malus() -> int:
	var ret = 0

	if _sleep_bonus_malus != 0:
		print("sleep bonus/malus: %s" % _sleep_bonus_malus)
		ret += _sleep_bonus_malus

	var time_awake = get_hours_awake()
	if time_awake > 16:
		@warning_ignore("integer_division")
		var wake_time_delta = (time_awake - 16) / 2
		print("wake time malus: %s" % wake_time_delta)
		ret += wake_time_delta

	var emo_delta = 0
	if absi(emotion) > 2:
		emo_delta = 1
	elif emotion == 0:
		emo_delta = -1
	if emo_delta != 0:
		print("Emo bonus/malus: %s" % emo_delta)
		ret += emo_delta

	var add_delta = 0
	if addiction <= -3:
		add_delta = 2
	elif addiction < 0:
		add_delta = 1
	elif addiction >= 4:
		add_delta = -3
	elif addiction == 3:
		add_delta = -2
	elif addiction > 0:
		add_delta = -1
	if add_delta != 0:
		print("Add bonus/malus: %s" % add_delta)
		ret += add_delta

	if wanted > 1:
		print("Wan malus: %s" % (wanted - 1))
		ret += wanted - 1

	var debt_delta = 0
	var debt_count = get_debt_count()
	if debt_count >= 4:
		debt_delta = 2
	elif debt_count == 3:
		debt_delta = randi_range(1, 2)
	elif debt_count == 2:
		debt_delta = 1
	if debt_delta != 0:
		print("unpaid bills malus: %s" % debt_delta)
		ret += debt_delta

	return ret

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.PLAYER

#
# For save/load.
#
func get_unique_id():
	return "player"

#
# For save/load.
#
func get_referenced_objects():
	return _mastery_cards + _fallback_cards

#
# For save/load.
#
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
		"drugs_taken_today": drugs_taken_today,
		"debts": _debts,
		"last_wake_time": _last_wake_time,
		"sleep_bonus_malus": _sleep_bonus_malus
	}
	if has_search_warrant:
		dict["has_search_warrant"] = true

	var card_refs = []
	for card in _mastery_cards:
		card_refs.append(card.get_unique_id())
	dict["cards"] = card_refs

	if not _fallback_cards.is_empty():
		card_refs = []
		for card in _fallback_cards:
			card_refs.append(card.get_unique_id())
		dict["fallback_cards"] = card_refs

	return dict

#
# For save/load.
#
func restore(dict, catalog):
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
	drugs_taken_today = dict.get("drugs_taken_today", 0)
	_debts.assign(dict.debts)
	_last_wake_time = dict.get("last_wake_time", 8)
	_sleep_bonus_malus = dict.sleep_bonus_malus
	if "has_search_warrant" in dict:
		has_search_warrant = dict.has_search_warrant
	for card_ref in dict.cards:
		_mastery_cards.append(catalog[card_ref])
	for card_ref in dict.get("fallback_cards", []):
		_fallback_cards.append(catalog[card_ref])

#
# For save/load.
#
static func allocate() -> Object:
	return Player.new()
