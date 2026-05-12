class_name Player extends RefCounted

var player_name: String
var job_id: String
var job_name: String
var job_bonus_malus: Dictionary
var sex: float
var physical: int: set = set_physical, get = get_physical
var mental: int: set = set_mental, get = get_mental
var health: int: set = set_health, get = get_health
var emotion: int: set = set_emotion, get = get_emotion
var addiction: int: set = set_addiction, get = get_addiction
var wanted: int: set = set_wanted, get = get_wanted
var paranoia: int
var money: int: set = set_money, get = get_money
var drugs: int: set = set_drugs, get = get_drugs
var drugs_taken_today: int
var has_search_warrant: bool
var next_dialogue_bonus_malus: int = 0

enum PlayerState {
	## Player is OK.
	OK,
	## Player is alive but must rest for 24 hours.
	KO,
	## Player is dead.
	DEAD
}

var _abstract_cards = preload("res://JSON/INTERACTION/Abstract.json").data
var _combat_cards = preload("res://JSON/INTERACTION/Combat.json").data
var _dialogue_cards = preload("res://JSON/INTERACTION/Dialogue.json").data
var _investigation_cards = preload("res://JSON/INTERACTION/Investigation.json").data

var _debts: Array[int]
var _mastery_cards: Array[Card]
var _fallback_cards: Array[Card]
var _discard_cards: Array[Card]
var _signal_pause: int = 0
var _last_sleep_time: int
var _last_wake_time: int
var _last_wanted_change: int
var _sleep_bonus_malus: int
var _in_jail_or_bed: bool
var _random_sms_count: int

func reset():
	_signal_pause += 1
	player_name = ""
	job_id = ""
	job_name = ""
	job_bonus_malus = {}
	sex = 0
	physical = 0
	mental = 0
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
	clear_discard_cards()
	_last_sleep_time = 0
	_last_wake_time = 0
	_last_wanted_change = 0
	_sleep_bonus_malus = 0
	_in_jail_or_bed = false
	_random_sms_count = 0
	_signal_pause -= 1

func start_game():
	_signal_pause += 1

	physical += job_bonus_malus.get("PHY", 0)
	mental += job_bonus_malus.get("MEN", 0)
	health += job_bonus_malus.get("HEA", 0)
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
	clear_discard_cards()
	_last_wake_time = GameState.get_time()
	_last_sleep_time = _last_wake_time - 8
	_last_wanted_change = 0
	_sleep_bonus_malus = 0
	_in_jail_or_bed = false
	_random_sms_count = 0

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
	is_minion: bool = false) -> String:
	var id = ""
	var ok = false
	while not ok:
		id = _combat_cards.keys().pick_random()
		match _combat_cards[id]["type"]:
			"Combat":
				ok = is_normal_ok
			"Combat SPECIAL":
				# cannot play a Do Not Kill card against a minion
				ok = is_special_ok and not (
					is_minion and CombatCard.is_do_not_kill_id(id))
			#"Combat RUN-AWAY":
			#	ok = is_run_away_ok
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
	for card_list in [_mastery_cards, _fallback_cards, _discard_cards]:
		for card in card_list:
			if card.get_card_type() == type and card.database_id == id:
				return true
	return false

func set_physical(phy: int):
	phy = clampi(phy, 0, 10)
	if physical != phy:
		physical = phy
		if _signal_pause == 0:
			GameState.physical_changed.emit()

func get_physical() -> int:
	return physical

func set_mental(men: int):
	men = clampi(men, 0, 10)
	if mental != men:
		mental = men
		if _signal_pause == 0:
			GameState.mental_changed.emit()

func get_mental() -> int:
	return mental

func set_health(hea: int):
	hea = clampi(hea, 0, 10)
	if health != hea:
		health = hea
		if _signal_pause == 0:
			GameState.health_changed.emit()

func get_health() -> int:
	return health

##
## Checks the player's health, emotion and addiction levels, and returns his
## status: OK, KO or DEAD. Note that if his emotion level reaches -5 or 5, that
## has negative consequences for his addiction level. And if his addiction level
## reaches -5 or 5, a message is displayed, indicating whether or not he has
## survived. A message is also displayed if he is too tired to continue (KO). As
## a result, this function is a coroutine to be awaited.
##
func test_health() -> PlayerState:
	if health <= 0:
		return PlayerState.DEAD

	while emotion <= -5 or emotion >= 5:
		addiction += 1 if addiction > 0 else -1
		emotion -= signi(emotion)

	if addiction <= -5 or addiction >= 5:
		var die = (health == 1 or randi_range(1, 10) > health)
		await Globals.dialog_overlay.show_addiction_message(die)
		if die:
			return PlayerState.DEAD
		addiction = 4 * signi(addiction)

	if physical <= 0 or mental <= 0:
		await Globals.dialog_overlay.announce_forced_rest(false)
		physical = mini(1, physical)
		mental = mini(1, mental)
		return PlayerState.KO

	if get_hours_awake() >= 24:
		await Globals.dialog_overlay.announce_forced_rest(true)
		return PlayerState.KO

	return PlayerState.OK

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
		_last_wanted_change = GameState.get_working_day()
		if _signal_pause == 0:
			GameState.wanted_changed.emit()

func get_wanted() -> int:
	return wanted

func get_wanted_malus() -> int:
	@warning_ignore("integer_division")
	return wanted / 2

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
	remove_debt(index)

func remove_debt(index: int):
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
func discard_mastery_card(card: Card) -> bool:
	var index = _mastery_cards.find(card)
	if index < 0:
		return false
	_mastery_cards.remove_at(index)
	card.queue_free()
	return true

##
## Moves the given card from the player's "discard" deck to his "mastery" deck.
## Returns true if successful, false if the card is not in the deck.
##
func undiscard_mastery_card(card: Card) -> bool:
	var index = _discard_cards.find(card)
	if index < 0:
		return false
	_discard_cards.remove_at(index)
	_mastery_cards.append(card)
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
## Removes the given card from the player's "fallback" deck, if found there. If
## keep_discard is true, the card is moved to the player's "discard" deck;
## otherwise, it is deleted. Returns true if successful, false if the card is
## not in the deck.
##
func discard_fallback_card(card: Card, keep_discard: bool) -> bool:
	var index = _fallback_cards.find(card)
	if index < 0:
		return false
	_fallback_cards.remove_at(index)
	if keep_discard:
		_discard_cards.append(card)
	else:
		card.queue_free()
	return true

##
## Returns the cards in the player's "discard" deck: cards he has used from the
## "fallback" deck during a recent interaction, or abstract cards from his
## "mastery" used during an interaction.
##
func get_discard_cards() -> Array[Card]:
	return _discard_cards

##
## Clears the player's "discard" deck, deleting any cards it contains.
##
func clear_discard_cards():
	for card in _discard_cards:
		card.queue_free()
	_discard_cards.clear()

##
## Awards the player some number of new cards, of any type, and which he does
## not already have. The cards are added to his "discard" deck, so that he can
## decide later which he wants to keep and which he does not.
##
func award_new_cards(count: int):
	for i in count:
		match randi() % 4:
			0:
				var id = _pick_random_abstract_card()
				_discard_cards.append(AbstractCard.create_card(id))
			1:
				var id = _pick_random_combat_card(true, true)
				_discard_cards.append(CombatCard.create_card(id))
			2:
				var id = _pick_random_dialogue_card()
				_discard_cards.append(DialogueCard.create_card(id))
			3:
				var id = _pick_random_investigation_card(true, true, true)
				_discard_cards.append(InvestigationCard.create_card(id))

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

	var normal_count = 0

	while _fallback_cards.size() < 5:
		var special_ok = normal_count + (5 - _fallback_cards.size()) > 1
		var id = _pick_random_investigation_card(true, special_ok)
		var card = InvestigationCard.create_card(id)
		_fallback_cards.append(card)
		if card.investigation_type == InvestigationCard.InvestigationType.NORMAL:
			normal_count += 1

##
## Picks 3 abstract and/or break-in cards at random for a break-in, ensuring
## that there are no duplicates with the player's "mastery" cards, and puts them
## in the player's "fallback" deck. Any cards already in the fallback deck are
## deleted.
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

##
## Picks 5 abstract and/or dialogue cards at random for a dialogue, ensuring
## that there are no duplicates with the player's "mastery" cards, and puts them
## in the player's "fallback" deck. Any cards already in the fallback deck are
## deleted.
##
func pick_dialogue_cards():
	clear_fallback_cards()

	# 2-5 dialogue cards

	var dialogue_count = randi_range(2, 5)

	while _fallback_cards.size() < dialogue_count:
		var id = _pick_random_dialogue_card()
		var card = DialogueCard.create_card(id)
		_fallback_cards.append(card)

	# the rest are abstract cards

	while _fallback_cards.size() < 5:
		var id = _pick_random_abstract_card()
		var card = AbstractCard.create_card(id)
		_fallback_cards.append(card)

##
## Picks 5 abstract and/or combat cards at random for a combat, ensuring that
## there are no duplicates with the player's "mastery" cards, and puts them in
## the player's "fallback" deck. Any cards already in the fallback deck are
## deleted.
##
## When combatting a minion (is_minion = true), special Do Not Kill cards are
## never picked, because you cannot dialogue with a minion.
##
func pick_combat_cards(is_minion: bool = false):
	clear_fallback_cards()

	# 0-2 abstract cards

	var abstract_count = randi() % 3

	while _fallback_cards.size() < abstract_count:
		var id = _pick_random_abstract_card()
		_fallback_cards.append(AbstractCard.create_card(id))

	# the rest are Combat (at least 2) and Combat SPECIAL cards

	var normal_count = 0

	while _fallback_cards.size() < 5:
		var special_ok = normal_count + (5 - _fallback_cards.size()) > 2
		var id = _pick_random_combat_card(true, special_ok, is_minion)
		var card = CombatCard.create_card(id)
		_fallback_cards.append(card)
		if card.combat_type == CombatCard.CombatType.NORMAL:
			normal_count += 1

##
## See pass_one_hour().
##
func pass_time(hours: int):
	for i in hours:
		pass_one_hour()

##
## For every waking hour, there is one chance in three that the player physical,
## mental or health attribute will improve.
##
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
## Picks 3 abstract and/or run-away cards at random for fleeing a combat,
## ensuring that there are no duplicates with the player's "mastery" cards, and
## puts them in the player's "fallback" deck. Any cards already in the fallback
## deck are deleted.
##
func pick_run_away_cards():
	clear_fallback_cards()

	# There is exactly one run-away card in the combat deck, with ID "COR001".
	# We give the player one chance in three of picking it, if he does not have
	# it in his mastery deck already. The other cards picked are all abstract.

	if (randi() % 3 == 0
		and not _have_card_already(Card.CardType.COMBAT, "COR001")):
		_fallback_cards.append(CombatCard.create_card("COR001"));

	while _fallback_cards.size() < 3:
		var id = _pick_random_abstract_card()
		_fallback_cards.append(AbstractCard.create_card(id))

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
## returns a value that is better (closer to zero) by at most how_much. If
## how_much is negative, returns a value that is farther from zero. 
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
## Returns false if the player has already slept today.
##
func can_sleep() -> bool:
	return GameState.get_time() - _last_sleep_time >= 20

##
## Puts the player to sleep for a certain number of hours. His health, emotion
## and addiction characteristics are updated accordingly, and it is noted that
## he will awake the given number of hours later.
##
func sleep(hours: int):
	_last_sleep_time = GameState.get_time()
	_last_wake_time = _last_sleep_time + hours

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
## any drugs yet today, to reduce his "wanted" level by 1, and to calm his
## emotions a bit.
##
func new_day():
	if not _in_jail_or_bed:
		drugs_taken_today = 0
		if wanted > 0 and GameState.get_working_day() - _last_wanted_change >= 3:
			wanted -= 1
		improve_emotion(1)

##
## Specifies that the player has been sent to prison. Until he is released,
## nights of sleep will have no effect on his wanted level or on his emotions,
## and he will not see any random text messages.
##
func begin_jail_term():
	_in_jail_or_bed = true

##
## Specifies that the player has been released from prison. It is assumed he has
## just gotten 8 hours of sleep. Note that this is a coroutine to be awaited.
##
func end_jail_term():
	await _end_jail_or_forced_rest(8)

##
## Specifies that the player has been sent to bed to rest, which has the same
## effect on him as 12 hours of sleep.
##
func begin_forced_rest():
	_in_jail_or_bed = true
	await sleep(12)

##
## Specifies that the player is allowed out of bed again. Note that this is a
## coroutine to be awaited.
##
func end_forced_rest():
	await _end_jail_or_forced_rest(12)

func _end_jail_or_forced_rest(sleep_time: int):
	_in_jail_or_bed = false
	drugs_taken_today = 0
	_last_wake_time = GameState.get_time()
	_last_sleep_time = _last_wake_time - sleep_time
	_sleep_bonus_malus = 0
	while _random_sms_count > 0:
		await Globals.dialog_overlay.send_random_sms()
		_random_sms_count -= 1

##
## Sends the player a random text message. If he has been sent to jail or to
## bed, he will not see the message until he is released or wakes up.
##
func receive_random_sms():
	if _in_jail_or_bed:
		_random_sms_count += 1
	else:
		await Globals.dialog_overlay.send_random_sms()

##
## Returns a bonus/malus to be added to dice rolls, depending on the player's
## emotion, addiction and wanted levels, how long it has been since he slept,
## how well he slept last time, the number of unpaid bills he has, the time,
## the difficulty of the current case... A negative number is a bonus, a
## positive number is a malus.
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

	var wanted_malus = get_wanted_malus()
	if wanted_malus > 0:
		print("Wan malus: %s" % wanted_malus)
		ret += wanted_malus

	@warning_ignore("integer_division")
	var debt_delta = get_debt_count() / 2
	if debt_delta > 0:
		print("unpaid bills malus: %s" % debt_delta)
		ret += debt_delta

	var hour = GameState.get_hour()
	if hour < 8 or hour >= 20:
		print("night action malus: 1")
		ret += 1

	var difficulty = GameState.get_current_case().get_difficulty()
	if difficulty != 3:
		var diff_delta = difficulty - 3
		print("case difficulty bonus/malus: %s" % diff_delta)

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
	return _mastery_cards + _fallback_cards + _discard_cards

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
		"emotion": emotion,
		"addiction": addiction,
		"wanted": wanted,
		"paranoia": paranoia,
		"money": money,
		"drugs": drugs,
		"drugs_taken_today": drugs_taken_today,
		"debts": _debts,
		"last_sleep_time": _last_sleep_time,
		"last_wake_time": _last_wake_time,
		"last_wanted_change": _last_wanted_change,
		"sleep_bonus_malus": _sleep_bonus_malus
	}
	if has_search_warrant:
		dict["has_search_warrant"] = true
	if next_dialogue_bonus_malus != 0:
		dict["next_dialogue_bonus_malus"] = next_dialogue_bonus_malus

	var card_refs = []
	for card in _mastery_cards:
		card_refs.append(card.get_unique_id())
	dict["cards"] = card_refs

	if not _fallback_cards.is_empty():
		card_refs = []
		for card in _fallback_cards:
			card_refs.append(card.get_unique_id())
		dict["fallback_cards"] = card_refs

	if not _discard_cards.is_empty():
		card_refs = []
		for card in _discard_cards:
			card_refs.append(card.get_unique_id())
		dict["discard_cards"] = card_refs

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
	_last_wanted_change = dict.get("last_wanted_change", 0)
	_last_sleep_time = dict.get("last_sleep_time", _last_wake_time - 8)
	_sleep_bonus_malus = dict.sleep_bonus_malus
	has_search_warrant = dict.get("has_search_warrant", false)
	next_dialogue_bonus_malus = dict.get("next_dialogue_bonus_malus", 0)
	for card_ref in dict.cards:
		_mastery_cards.append(catalog[card_ref])
	for card_ref in dict.get("fallback_cards", []):
		_fallback_cards.append(catalog[card_ref])
	for card_ref in dict.get("discard_cards", []):
		_discard_cards.append(catalog[card_ref])

#
# For save/load.
#
static func allocate() -> Object:
	return Player.new()
