extends Node

enum PlayerLocation {
	OFFICE,
	INVESTIGATION_CENTER,
	DOCTOR,
	ROWENA,
	WARRANT_DESK,
	PRISON,
	OTHER
}

enum InteractionType {
	NONE,
	DIALOGUE,
	COMBAT,
	INVESTIGATION,
	BREAK_IN,
	RUN_AWAY
}

## The outcome of a dialogue, a combat or an investigation.
enum InteractionOutcome {
	## The interaction was a failure.
	FAILURE,
	## The interaction was a success.
	SUCCESS,
	## The combat was successful and should be followed by a dialogue.
	CONTINUE
}

##
## Constants representing time slots during the work week or the weekend. They
## can be used as flags for a bit mask.
##
enum TimeSlot {
	# 8-12 Monday to Friday
	MORNING = 0x01,
	# 12-16 Monday to Friday
	AFTERNOON = 0x02,
	# 16-20 Monday to Friday
	EVENING = 0x04,
	# 20-8 Monday to Friday
	NIGHT = 0x08,
	# 8-12 Saturday and Sunday
	WE_MORNING = 0x10,
	# 12-16 Saturday and Sunday
	WE_AFTERNOON = 0x20,
	# 16-20 Saturday and Sunday
	WE_EVENING = 0x40,
	# 20-8 Saturday and Sunday
	WE_NIGHT = 0x80,

	# ALL weekday time slots
	WEEKDAY = 0x0f,
	# ALL weekend time slots
	WEEKEND = 0xf0,
	# ALL time slots
	ALWAYS = 0xff
}

enum CombatDamage {
	NONE,
	HIT,
	CRITICAL_HIT
}

enum NpcCombatState {
	ESCAPED,
	DEAD,
	WILL_TALK
}

enum NpcEscapeOutcome {
	STAYED,
	FAILED,
	SUCCEEDED
}

var player: Player = Player.new()
var cases: Array[Case]

## Signal emitted when the time has changed: see get_day() and get_hour().
@warning_ignore("unused_signal")
signal time_changed

## Signal emitted when the current case has changed: see get_current_case().
signal case_changed

## Signal emitted when the player changes location.
signal location_changed

## Signal emitted when the player's PHY attribute has changed.
@warning_ignore("unused_signal")
signal physical_changed

## Signal emitted when the player's MEN attribute has changed.
@warning_ignore("unused_signal")
signal mental_changed

## Signal emitted when the player's HEA attribute has changed.
@warning_ignore("unused_signal")
signal health_changed

## Signal emitted when the player's Emo attribute has changed.
@warning_ignore("unused_signal")
signal emotion_changed

## Signal emitted when the player's Add attribute has changed.
@warning_ignore("unused_signal")
signal addiction_changed

## Signal emitted when the player's Wan attribute has changed.
@warning_ignore("unused_signal")
signal wanted_changed

## Signal emitted when the amount of money in the player's possession has
## changed.
@warning_ignore("unused_signal")
signal money_changed

## Signal emitted when the number of drug doses in the player's possession has
## changed.
@warning_ignore("unused_signal")
signal drugs_changed

## Signal emitted when the number of unpaid bills in the player's possession has
## changed.
@warning_ignore("unused_signal")
signal debts_changed

## Signal emitted when the player has succumbed to paranoia (happens only once).
signal paranoia

## Signal emitted when the player has died.
signal died

## Signal emitted when the player starts an interaction.
signal interaction_started

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

# where game state is saved/reloaded
const _save_path = "user://game.sav"

# play starts at 8am Monday
const _start_time = 8

# hours passed since the first Monday at midnight
var _hour: int

# time when the player will be sent a random SMS, if he is on a case
var _random_sms_time: int

# the last day the player took on a new case at the investigation center
var _last_new_case_day: int

# the last day the player visited the doctor
var _last_doctor_day: int

# the last working day the player visited Rowena the dealer
var _last_dealer_day: int

# how many doses has Rowena got to sell?
var _dealer_drug_stock: int

# the crimes of the last several cases generated, to avoid repetition
var _last_crimes: Array[String]

# which case is current?
var _current_case_index: int

# player location
var _player_location: PlayerLocation = PlayerLocation.OFFICE
var _player_location_card: LocationCard

# current interaction
var _current_interaction: InteractionType = InteractionType.NONE
var _current_interaction_location: PlayerLocation = PlayerLocation.OTHER
var _current_interaction_location_card: LocationCard
var _current_interaction_npc: NpcCard
var _current_interaction_bonus_malus: int
var _current_interaction_do_not_kill: bool

var _npc_link_types = [
	Link.Type.DEBT,
	Link.Type.INTIMACY,
	Link.Type.FRIEND,
	Link.Type.ENEMY,
	Link.Type.ACQUAINTANCE,
	Link.Type.IDEOLOGY
]

#
# Represents a piece of information, that is, a connection between two cards,
# which may or may not actually exist.
#
class InfoToReveal:
	var card1: Card
	var card2: Card
	var link_type: Link.Type
	
	func _init(_card1: Card, _card2: Card, _link_type: Link.Type):
		card1 = _card1
		card2 = _card2
		link_type = _link_type

	#
	# Returns true if two pieces of information are the same.
	#
	func compare(other: InfoToReveal) -> bool:
		return (link_type == other.link_type and
				card1 in [other.card1, other.card2] and 
				card2 in [other.card1, other.card2])

func _ready():
	load_game()

func start_game():
	_hour = _start_time
	_random_sms_time = -1
	_last_new_case_day = -1
	_last_doctor_day = -1
	_last_dealer_day = -1
	_dealer_drug_stock = randi_range(3, 7)
	_last_crimes.clear()
	_current_case_index = -1
	_player_location = PlayerLocation.INVESTIGATION_CENTER
	_player_location_card = null
	_reset_interaction()

	cases.clear()
	for i in 5:
		add_new_case()

	player.start_game()

func add_new_case():
	cases.append(Case.generate())

func _reset_interaction():
	_current_interaction = InteractionType.NONE
	_current_interaction_location = PlayerLocation.OTHER
	_current_interaction_location_card = null
	_current_interaction_npc = null
	_current_interaction_bonus_malus = 0
	_current_interaction_do_not_kill = false

func end_game():
	cases.clear()
	player.reset()
	DirAccess.remove_absolute(_save_path)

##
## Returns the number of hours that have passed since midnight of the day play
## began.
##
func get_time() -> int:
	return _hour

##
## Returns the number of full days that have passed since play began. Play
## always begins on Monday, so the number of days % 7 gives you the day of the
## week (0 for Monday).
##
## If travel_time is not zero, it is added to the current time first.
##
func get_day(travel_time: int = 0) -> int:
	@warning_ignore("integer_division")
	return (_hour + travel_time) / 24

##
## Like get_day(), but considers that the day starts at 8 AM.
##
func get_working_day(travel_time: int = 0) -> int:
	@warning_ignore("integer_division")
	return (_hour + travel_time - 8) / 24

##
## Returns the current time (hour), in the range 0-23. If travel_time is not
## zero, it is added to the current time first.
##
func get_hour(travel_time: int = 0) -> int:
	return (_hour + travel_time) % 24

##
## Returns the current time slot: morning, afternoon, evening or night; weekday
## or weekend. If travel_time is not zero, it is added to the current time
## first.
##
func get_time_slot(travel_time: int = 0) -> TimeSlot:
	var hour = get_hour(travel_time)
	var workday = get_working_day(travel_time) % 7
	if hour < 8 or hour >= 20:
		return TimeSlot.NIGHT if workday < 5 else TimeSlot.WE_NIGHT
	elif hour < 12:
		return TimeSlot.MORNING if workday < 5 else TimeSlot.WE_MORNING
	elif hour < 16:
		return TimeSlot.AFTERNOON if workday < 5 else TimeSlot.WE_AFTERNOON
	else:
		return TimeSlot.EVENING if workday < 5 else TimeSlot.WE_EVENING

#
# Increments the given time by the given number of hours. If check_player_status
# is true, the player's health, wanted status, debts and paranoia status are
# checked as well. One or more messages may be displayed, making this is a
# coroutine to be awaited, and, if check_player_status is true, the player may
# have suffered a paranoia attack or died on return.
#
func _increment_time(hours: int, check_player_status: bool):
	while hours > 0:

		# move forward at most to the beginning of the next working day (8 AM),
		# or to the time when the player is to receive a random SMS

		var to_next_working_day
		var now = get_hour()
		if now < 8:
			to_next_working_day = 8 - now
		else:
			to_next_working_day = 32 - now
		var delta = mini(hours, to_next_working_day)

		if _random_sms_time >= 0:
			delta = mini(hours, _random_sms_time - _hour)

		_hour += delta
		hours -= delta

		# time for a random SMS?

		if _random_sms_time >= _hour:
			if _current_case_index >= 0:
				await player.receive_random_sms()
			_random_sms_time = -1

		# stuff to do at the start of each working day

		if get_hour() == 8:
			await _new_day()

		# check player's health, wanted status, debts, paranoia status, etc.

		if check_player_status:
			await _check_player_status()
			if player.health <= 0:
				return

	time_changed.emit()
	save_game()

#
# Checks the player's health, wanted status, debts and paranoia status. One or
# more messages may be displayed, making this a coroutine to be awaited. The
# player may also be forced to rest, sent to prison or die.
#
func _check_player_status():
	match await player.test_health():
		Player.PlayerState.KO:
			await _send_player_to_bed()

		Player.PlayerState.DEAD:
			died.emit()
			return

	if player.wanted >= 5:
		var bail: int = 125 if Globals.vice_flag else 100
		var can_pay = (player.money >= bail)
		var pay = await Globals.dialog_overlay.announce_prison_for_wanted(
			true, bail, can_pay)
		player.wanted = 0
		if pay:
			player.money -= bail
		else:
			_send_player_to_prison()

	if player.get_debt_count() >= 5:
		await Globals.dialog_overlay.announce_prison_for_debts()
		while player.get_debt_count() >= 5:
			player.remove_debt(0)
		_send_player_to_prison()

	await _check_for_paranoia_attack()

#
# Sends the player to bed for about 24 hours (until 8 AM the following day or
# the day after).
#
func _send_player_to_bed():
	if _player_location != PlayerLocation.OFFICE:
		set_player_location(PlayerLocation.OFFICE)
	var hour = get_hour()
	var duration
	if hour < 18:
		duration = 32 - hour
	else:
		duration = 56 - hour

	player.begin_forced_rest()
	await _increment_time(duration, false)
	await player.end_forced_rest()

	save_game()

#
# Sends the player sent to prison, where he spends 3 nights (4 nights if he
# arrives in the evening) and is released at 8 AM.
#
func _send_player_to_prison():
	if _player_location != PlayerLocation.PRISON:
		set_player_location(PlayerLocation.PRISON)
	var hour = get_hour()
	var duration
	if hour < 20:
		duration = 80 - hour
	else:
		duration = 104 - hour

	player.begin_jail_term()
	await _increment_time(duration, false)
	await player.end_jail_term()

	save_game()

#
# Stuff that needs to be dealt with at the start of each new working day.
#
func _new_day():

	# every Monday the player is sent a new bill, and Rowena replenishes her
	# stock of drugs

	if get_working_day() % 7 == 0:
		_send_new_bill()
		await Globals.dialog_overlay.show_debt_reminder()
		_dealer_drug_stock = randi_range(3, 7)
	else:
		if _dealer_drug_stock > 0 and randi() % 4 == 0:
			_dealer_drug_stock -= 1

	# increment the health of NPCs in active cases, and check whether they have
	# expired

	var expired_cases: Array[int]

	for index in cases.size():
		var case = cases[index]
		if case.get_status() in [Case.Status.ACTIVE, Case.Status.PAUSED]:
			if case.is_expired():
				if case and case.is_final():
					died.emit()
					return
				if player.emotion == 0:
					player.emotion = -1
				else:
					player.improve_emotion(-1)
				# expired case indexes are stored in DECREASING order to
				# simplify their deletion below
				expired_cases.insert(0, index)
			else:
				case.new_day()

	if expired_cases:
		# closed cases are deleted, changing the indexes of the cases following
		# them in the list, but we stored indexes in decreasing order above
		for index in expired_cases:
			_close_case(index)
		await Globals.dialog_overlay.show_case_expired()

	# every day, there is 1 chance in 5 that the player will receive a random
	# SMS at a random time in the next 16 hours

	var smsrand = randi()
	if smsrand % 5 == 0:
		@warning_ignore("integer_division")
		_random_sms_time = _hour + ((smsrand / 5) % 17)
	else:
		_random_sms_time = -1

	# things that happen to the player every morning

	player.new_day()

func _send_new_bill():
	for i in player.get_debt_count():
		var debt = player.get_debt(i)
		player.set_debt(i, roundi(debt * 1.1))

	var new_debt = 90 if Globals.inflation_flag else 75
	var x = randf()
	if x < 0.5:
		#new_debt = roundi(new_debt * randf_range(0.9, 1.1))
		new_debt = roundi(new_debt * (1 + (0.1 / 0.25) * (x - 0.25)))
	player.add_debt(new_debt)

##
## Returns a category of crime taken from the JSON crime definitions. It is
## guaranteed that any 5 sequential calls will return 5 unique crimes.
##
func get_new_crime() -> String:
	var crime: String
	var crime_count = _crime_data.size()

	while crime.is_empty() or crime in _last_crimes:
		crime = _crime_data.keys()[randi() % crime_count]

	if _last_crimes.size() == 5:
		_last_crimes.pop_front()
	_last_crimes.push_back(crime)

	return crime

##
## Lets an hour pass. Note that this is a coroutine to be awaited, and also that
## the player may have died on return.
##
## In the "final" case, when the player is paranoid, pass_time() skips four
## hours, not just one.
##
func pass_time():
	var hours = 4 if player.is_paranoid() else 1
	var case = get_current_case()
	if case and case.check_minion_attack() and not _player_location in [
		PlayerLocation.OFFICE, PlayerLocation.PRISON
	]:
		await start_minion_attack()
	else:
		player.pass_time(hours)
		await _increment_time(hours, true)

func _pass_one_hour_private():
	player.pass_time(1)
	await _increment_time(1, true)

##
## Takes the player back to the office, if he is not there already, then puts
## him to sleep for the given number of hours. Note that this is a coroutine to
## be awaited, and also that the player may wake up dead!
##
func sleep(hours: int):
	if await move_player_to(PlayerLocation.OFFICE) and player.health > 0:
		await player.sleep(hours)
		await _increment_time(hours, true)

func _is_office_hours(travel_time: int = 0) -> bool:
	var day = get_day(travel_time) % 7
	var hour = get_hour(travel_time)
	return day < 5 and hour >= 8 and hour < 20

func can_visit_investigation_center() -> bool:
	var travel_time = 0 if _player_location == PlayerLocation.INVESTIGATION_CENTER else 1
	return _is_office_hours(travel_time)

func visit_investigation_center():
	if await move_player_to(PlayerLocation.INVESTIGATION_CENTER) and player.health > 0:
		if await Globals.dialog_overlay.open_investigation_center():
			_last_new_case_day = get_day()

func can_take_new_case() -> bool:
	var open_cases = get_open_cases()
	if open_cases.is_empty():
		return true
	if open_cases.size() >= 4:
		return false
	return _last_new_case_day < 0 || _last_new_case_day < get_day()

func visit_office():
	if await move_player_to(PlayerLocation.OFFICE) and player.health > 0:
		await Globals.dialog_overlay.open_office()

func can_visit_warrant_desk() -> bool:
	var travel_time = 0 if _player_location == PlayerLocation.WARRANT_DESK else 1
	return _is_office_hours(travel_time)

func get_warrant_price() -> int:
	var price: int = 45
	if Globals.corruption_flag:
		price = roundi(price * 1.2)
	return price

func buy_search_warrant():
	if await move_player_to(PlayerLocation.WARRANT_DESK) and player.health > 0:
		var price = get_warrant_price()
		if await Globals.dialog_overlay.buy_search_warrant(price):
			player.money -= price
			player.has_search_warrant = true
			save_game()

func pay_debt(debt_index: int):
	if await move_player_to(PlayerLocation.OFFICE) and player.health > 0:
		await _pass_one_hour_private()
		await player.pay_debt(debt_index)

func use_drugs(doses: int):
	if await move_player_to(PlayerLocation.OFFICE) and player.health > 0:
		await _pass_one_hour_private()
		await player.use_drugs(doses)

func get_player_drug_price() -> int:
	var price: int = 35
	var markup: float = 1.2 if Globals.drug_quality_flag else 1.0
	markup *= player.job_bonus_malus.get("dealer_discount", 1.0)
	return roundi(price * markup)

func can_visit_dealer() -> bool:
	var price = get_player_drug_price()
	var travel_time = 0 if _player_location == PlayerLocation.ROWENA else 1
	var eta = get_hour() + travel_time
	return ((eta < 8 or eta >= 20)
			and player.money >= price and player.get_debt_count() == 0
			and _last_dealer_day < get_working_day())

func visit_dealer():
	if not (await move_player_to(PlayerLocation.ROWENA) and player.health > 0):
		return

	var price = get_player_drug_price()

	var doses = await Globals.dialog_overlay.visit_dealer(
		_dealer_drug_stock, player.money, price)

	if doses > 0:
		_dealer_drug_stock -= doses
		player.money -= doses * price
		player.drugs += doses

	_last_dealer_day = get_working_day()
	save_game()

func get_player_doctor_fee() -> int:
	var price: int = 75
	if "doctor_discount" in player.job_bonus_malus:
		price = roundi(price * player.job_bonus_malus.doctor_discount)
	return price

func can_visit_doctor() -> bool:
	var travel_time = 0 if _player_location == PlayerLocation.DOCTOR else 1
	var fee = get_player_doctor_fee()
	if (not _is_office_hours(travel_time)
		or player.money < fee or player.get_debt_count() > 0):
		return false
	return _last_doctor_day < 0 or get_day(travel_time) - _last_doctor_day >= 4

func visit_doctor():
	if not (await move_player_to(PlayerLocation.DOCTOR) and player.health > 0):
		return

	var fee = get_player_doctor_fee()

	if await Globals.dialog_overlay.visit_doctor(fee):
		player.money -= fee
		player.health += 3
		player.improve_emotion(2)
		player.improve_addiction(1)
		_last_doctor_day = get_day()
		save_game()

#
# Returns true if location is a place of residence but all its residents are in
# jail.
#
func _are_residents_in_jail(location: LocationCard) -> bool:
	var npcs = location.find_linked_cards(Link.Type.HOME)
	if npcs.is_empty():
		return false
	for npc in npcs:
		if npc is NpcCard and npc.npc_status != NpcCard.NpcStatus.JAIL:
			return false
	return true

func attempt_investigation(location: LocationCard):

	# go to the location first

	if not (await move_player_to(PlayerLocation.OTHER, location)
			and player.health > 0 and get_current_case()):
		return

	# check whether there is anybody there, whether the player has a warrant he
	# can use or if he wants to break in, etc.

	var break_in_needed = false

	if not location.is_open_for_business():

		# if no NPCs are present, the player can either try to break in or leave
		# except for one special case: if this is a residence and all the
		# residents are in prison, the player can enter with a warrant

		if not (location.get_npcs_present() or _are_residents_in_jail(location)):
			if not await Globals.dialog_overlay.confirm_break_in():
				return
			break_in_needed = true

		# if NPCs are present and the player has a search warrant, ask if he
		# wants to use it

		elif GameState.player.has_search_warrant:
			if not await Globals.dialog_overlay.use_search_warrant():
				return
			GameState.player.has_search_warrant = false

		# if NPCs are present and the player does NOT have a search warrant,
		# there is nothing he can do

		else:
			await Globals.dialog_overlay.no_search_warrant()
			return

	location.set_investigated_today()

	# if nobody is there and the player wants to break in, set up the pseudo-
	# interaction (pseudo because it takes place not in the Interaction scene
	# but in an overlay of the Main scene) and try to break in

	if break_in_needed:
		player.pick_break_in_cards()
		_current_interaction = InteractionType.BREAK_IN
		_current_interaction_location = PlayerLocation.OTHER
		_current_interaction_location_card = location
		save_game()
		var cards = await Globals.dialog_overlay.attempt_break_in()
		if not await _play_break_in(cards):
			await end_interaction()
			return

	# finally, start the investigation

	await start_investigation(location)

##
## Called if the game was interrupted during a break-in, to resume where we
## left off.
##
func resume_break_in():
	var cards = await Globals.dialog_overlay.attempt_break_in()
	if await _play_break_in(cards):
		await start_investigation(_current_interaction_location_card)
	else:
		await end_interaction()

##
## Called if the game was interrupted during a run-away attempt, to resume where
## we left off.
##
func resume_run_away():
	var cards = await Globals.dialog_overlay.attempt_run_away()
	if await _play_run_away(cards):
		await end_interaction()
	else:
		start_combat(
			_current_interaction_npc, _current_interaction_location,
			_current_interaction_location_card)

#
# "Plays" the given cards, tracking any temporary bonus/malus effects in the
# returned InteractionAttributes instance. Changes made by the cards to the
# player's Emo and Add attributes are made directly, and are permanent.
#
func _play_cards(cards: Array[Card]) -> InteractionAttributes:
	var attrs = InteractionAttributes.new()
	if _current_interaction_location_card:
		attrs.play_card(_current_interaction_location_card, false)
	for card in cards:
		attrs.play_card(card, card in player.get_fallback_cards())
	return attrs

#
# Discards abstract cards played from the mastery deck, and all cards played
# from the fallback deck. If success is true, fallback cards are moved to the
# player's "discard" deck; if not, they are deleted.
#
func _discard_cards(cards: Array[Card], success: bool):
	for card in cards:
		if card in player.get_fallback_cards():
			player.discard_fallback_card(card, success)
		elif card is AbstractCard:
			player.discard_mastery_card(card)

#
# Game logic for a break-in. Given the current location card, and the optional
# cards played (break-in and/or abstract cards), rolls the dice to determine
# whether the break-in is successful or not. Returns true if the break-in is
# successful.
#
func _play_break_in(cards_played: Array[Card]) -> bool:
	print("\n*** break-in: %s ***" % _current_interaction_location_card.get_display_name())

	# roll the die

	var attrs: InteractionAttributes = _play_cards(cards_played)
	var bonus_malus = attrs.get_bonus_malus()
	if cards_played.is_empty():
		bonus_malus += 1
		print("no cards played malus: 1")
	var max_roll = roundi((attrs.PHY + attrs.MEN + attrs.HEA) / 3.0)
	print("max roll: %s" % max_roll)
	var actual_roll = randi_range(1, 10)
	print("actual roll: %s" % actual_roll)
	var net_roll = actual_roll + bonus_malus
	print("with bonus/malus: %s" % net_roll)

	var success: bool
	var critical_attr: StringName

	if actual_roll == 10:
		if randi() & 1:
			player.physical -= 1
			critical_attr = &"PHY"
		else:
			player.mental -= 1
			critical_attr = &"MEN"
		player.health -= 1
		player.emotion = Player.exacerbate(player.emotion)
		player.wanted += 1
		print("critical failure: update HEA, %s, Emo, Wan" % critical_attr)
		success = false
	elif actual_roll == 1:
		if randi() & 1:
			player.physical += 1
			critical_attr = &"PHY"
		else:
			player.mental += 1
			critical_attr = &"MEN"
		player.emotion = Player.calm(player.emotion)
		print("critical success: update %s, Emo" % critical_attr)
		_current_interaction_bonus_malus = -1
		success = true
	elif net_roll > max_roll:
		player.emotion = Player.exacerbate(player.emotion)
		player.wanted += 1
		print("failure: update Emo, Wan")
		success = false
	else:
		print("success: margin = %s" % [max_roll - net_roll])
		success = true

	if actual_roll == 10:
		await Globals.dialog_overlay.show_player_improvement(-1)
	elif actual_roll == 1:
		await Globals.dialog_overlay.show_player_improvement(1, critical_attr)
	else:
		await Globals.dialog_overlay.show_break_in_message(success)

	_discard_cards(cards_played, success)
	return success

#
# Game logic for a run-away attempt before a combat. Given the current location
# and NPC, and the optional cards played (run-away and/or abstract cards), rolls
# the dice to determine whether the attempt is successful or not. Returns true
# if it is.
#
func _play_run_away(cards_played: Array[Card]) -> bool:
	print("\n*** run away: %s ***" % _current_interaction_location_card.get_display_name())

	# roll the die

	var attrs: InteractionAttributes = _play_cards(cards_played)
	var bonus_malus = attrs.get_bonus_malus()
	if cards_played.is_empty():
		bonus_malus += 1
		print("no cards played malus: 1")
	var max_roll = roundi((attrs.PHY * 2 + attrs.MEN + attrs.HEA) / 4.0)
	print("max roll: %s" % max_roll)
	var actual_roll = randi_range(1, 10)
	print("actual roll: %s" % actual_roll)
	var net_roll = actual_roll + bonus_malus
	print("with bonus/malus: %s" % net_roll)

	var tweak_attr = func(value) -> StringName:
		match randi() % 5:
			0, 1, 2:
				player.physical += value
				return &"PHY"
			3:
				player.mental += value
				return &"MEN"
			_:
				player.health += value
				return &"HEA"

	var success: bool
	var critical_attr: StringName

	if actual_roll == 10:
		critical_attr = tweak_attr.call(-1)
		print("critical failure: update %s" % critical_attr)
		success = false
	elif actual_roll == 1:
		critical_attr = tweak_attr.call(1)
		print("critical success: update %s" % critical_attr)
		success = true
	elif net_roll > max_roll:
		print("failure")
		success = false
	else:
		print("success: margin = %s" % [max_roll - net_roll])
		success = true

	if not success:
		player.next_dialogue_bonus_malus = 1

	await Globals.dialog_overlay.show_run_away_message(success)

	if actual_roll == 10:
		await Globals.dialog_overlay.show_player_improvement(-1)
	elif actual_roll == 1:
		await Globals.dialog_overlay.show_player_improvement(1, critical_attr)

	_discard_cards(cards_played, success)
	return success

#
# Game logic for an investigation (possibly following a break-in).
#
func _play_investigation(cards_played: Array[Card]) -> InteractionOutcome:
	print("\n*** investigation: %s ***" % _current_interaction_location_card.get_display_name())
	print("player attributes at start: MEN %d, PHY %d, HEA %d"
		  % [player.mental, player.physical, player.health])

	# roll the die

	var attrs: InteractionAttributes = _play_cards(cards_played)
	var bonus_malus = attrs.get_bonus_malus()
	if _current_interaction_bonus_malus != 0:
		bonus_malus += _current_interaction_bonus_malus
		print("break-in bonus: %s" % _current_interaction_bonus_malus)
	var max_roll = roundi((attrs.PHY + attrs.MEN + attrs.HEA) / 3.0)
	print("max roll: %s" % max_roll)
	var actual_roll = randi_range(1, 10)
	print("actual roll: %s" % actual_roll)
	var net_roll = actual_roll + bonus_malus
	print("with bonus/malus: %s" % net_roll)

	var tweak_attr = func(who, value) -> StringName:
		match randi() % 3:
			0:
				who.mental += value
				return &"MEN"
			1:
				who.physical += value
				return &"PHY"
			_:
				who.health += value
				return &"HEA"

	var success: bool
	var critical_attr: StringName
	var money_found: int = 0
	var infos_found: int = 0

	if actual_roll == 10:
		player.health -= 1
		critical_attr = tweak_attr.call(player, -1)
		print("critical failure: update HEA, %s" % critical_attr)
		success = false
	elif actual_roll == 1:
		critical_attr = tweak_attr.call(player, 1)
		money_found = randi_range(25, 50)
		player.money += money_found
		print("critical success: update %s, money" % critical_attr)
		success = true
	elif net_roll > max_roll:
		player.emotion -= 1
		print("failure: update Emo")
		success = false
	else:
		print("success")
		success = true

	# if successful, reveal newly discovered information (NPCs and/or objects)

	if success and net_roll <= max_roll:
		var margin = max_roll - net_roll
		var total_count = roundi(margin / 3.0)
		var evidence_count = 1 if margin >= 3 else 0
		print("success margin: %s" % margin)
		infos_found = _get_unknown_connections_to_location(
			_current_interaction_location_card, evidence_count, total_count)
		save_game()

	# display messages, increment the time, discard the cards that were played

	if actual_roll == 10:
		await Globals.dialog_overlay.show_player_improvement(-1)
	elif actual_roll == 1:
		await Globals.dialog_overlay.show_player_improvement(1, critical_attr)

	var duration = 2
	var other_bonus_malus = attrs.get_post_bonus_malus(success)
	var hours_bonus_malus = other_bonus_malus.get("hours", [])
	for h in hours_bonus_malus:
		duration += h as int
	print("duration: %s hour(s)" % duration)

	if player.health > 0:
		await Globals.dialog_overlay.show_investigation_result(
			success, actual_roll in [1, 10], money_found, infos_found)

	if duration > 0:
		# player's status (health, etc.) will be checked in end_interaction()
		await _increment_time(duration, false)
		player.pass_time(duration)

	_discard_cards(cards_played, success)
	return InteractionOutcome.SUCCESS if success else InteractionOutcome.FAILURE

##
## Starts an investigation interaction: picks the fallback cards for the
## investigation, saves the state of the cards in the Main scene (before we
## switch to the Interaction scene), and emits an interaction_started() signal
## telling The Game to switch scenes.
##
func start_investigation(location: LocationCard):

	# has player stumbled upon any new victims?

	await _check_for_new_victims(location)

	# start the interaction

	player.pick_investigation_cards()
	_current_interaction = InteractionType.INVESTIGATION
	_current_interaction_location = PlayerLocation.OTHER
	_current_interaction_location_card = location
	_push_card_state()
	save_game()
	interaction_started.emit()

#
# Checks for new victims when the player arrives in the given location for the
# first time. Displays a message, reveals the victim cards and returns true if
# any are found.
#
func _check_for_new_victims(location: LocationCard) -> bool:
	var ret = false
	for card in location.get_connections(Link.Type.FOUND):
		if card is NpcCard and card.reveal_status != Card.RevealStatus.REVEALED:
			#print("*** reveal victim: ", card.get_display_name())
			_reveal_card(card)
			get_current_case().create_link(
				card, location, Link.Type.FOUND, true, true)
			ret = true
	if ret:
		#print("*** show_dead_victim")
		await Globals.dialog_overlay.show_dead_victim()
		#print("*** random SMS")
		await player.receive_random_sms()
		_random_sms_time = -1
	return ret

##
## Note that a null location means the NPC is in jail.
##
func attempt_dialogue(npc: NpcCard, location: LocationCard):

	# go to the location first

	var got_there: bool
	if location:
		got_there = await move_player_to(PlayerLocation.OTHER, location)
	else:
		got_there = await move_player_to(PlayerLocation.PRISON)
	if not (got_there and player.health > 0 and get_current_case()):
		return

	# check whether the NPC is there

	if location and npc.locate() != location:
		await Globals.dialog_overlay.show_npc_away(npc)
		return

	var is_first_visit = not npc.has_been_seen()
	npc.visit()

	# the NPC may try to run away

	var npc_fled := NpcEscapeOutcome.STAYED
	if not is_first_visit and location:
		npc_fled = await _does_npc_run(npc)
		if npc_fled == NpcEscapeOutcome.SUCCEEDED:
			return

	# if the NPC attacks the player, start a combat, not a dialogue, and give
	# the player the chance to try to run away first

	if (not is_first_visit and location and npc_fled == NpcEscapeOutcome.STAYED
		and _does_npc_attack(npc)):
		await Globals.dialog_overlay.show_attack_message(npc)
		if await Globals.dialog_overlay.confirm_run_away():
			player.pick_run_away_cards()
			_current_interaction = InteractionType.RUN_AWAY
			_current_interaction_location = PlayerLocation.OTHER
			_current_interaction_location_card = location
			_current_interaction_npc = npc
			save_game()
			var cards = await Globals.dialog_overlay.attempt_run_away()
			if await _play_run_away(cards):
				await end_interaction()
				return
		start_combat(npc, PlayerLocation.OTHER, location)
	else:
		await start_dialogue(npc, location)

##
## Starts a dialogue interaction: picks the fallback cards for the dialogue,
## saves the state of the cards in the Main scene (before we switch to the
## Interaction scene), and emits an interaction_started() signal telling The
## Game to switch scenes.
##
## Note that a location of null means the dialogue takes place in prison.
##
## There is one case where we do NOT want the state of the cards to be saved
## first: when going directly from a combat to a dialogue, because we are
## already in the Interaction scene. In that case, save_card_state should be
## false.
##
func start_dialogue(
		npc: NpcCard, location: LocationCard, save_card_state: bool = true):

	# has player stumbled upon any new victims?

	if location:
		await _check_for_new_victims(location)

	# start the interaction

	player.pick_dialogue_cards()
	_current_interaction = InteractionType.DIALOGUE
	if location:
		_current_interaction_location = PlayerLocation.OTHER
		_current_interaction_location_card = location
	else:
		_current_interaction_location = PlayerLocation.PRISON
		_current_interaction_location_card = null
	_current_interaction_npc = npc
	if save_card_state:
		_push_card_state()
	save_game()
	interaction_started.emit()

#
# Game logic for a dialogue (possibly following a combat).
#
func _play_dialogue(cards_played: Array[Card]) -> InteractionOutcome:
	var npc: NpcCard = _current_interaction_npc
	print("\n*** dialogue: %s ***" % npc.get_display_name())
	print("player attributes at start: MEN %d, PHY %d, HEA %d"
		  % [player.mental, player.physical, player.health])

	var attrs: InteractionAttributes = _play_cards(cards_played)
	var bonus_malus = attrs.get_bonus_malus()
	var rep = npc.player_reputation
	if rep != 0:
		bonus_malus -= rep
		print("Rep bonus/malus: %s" % -rep)
	if player.next_dialogue_bonus_malus != 0:
		bonus_malus += player.next_dialogue_bonus_malus
		print("dialogue bonus/malus: %s" % player.next_dialogue_bonus_malus)
		player.next_dialogue_bonus_malus = 0

	# which card did the player ask for information about?

	var subject_card: Card = npc
	for card in cards_played:
		if card.get_card_type() in [
				Card.CardType.OBJECT, Card.CardType.LOCATION, Card.CardType.NPC]:
			subject_card = card
			break

	# if the player played a card from the evidence pile but it is NOT
	# evidence, give him a malus of 1; if he played a card with a correct
	# incriminating link, give him a bonus of 2

	var evidence_malus: int = 0

	if subject_card is ObjectCard:
		if subject_card.is_object_evidence:
			if subject_card in get_current_case().evidence:
				evidence_malus -= 2
			else:
				evidence_malus += 1
	elif subject_card is NpcCard:
		var bad_roles = [NpcCard.NpcRole.CULPRIT, NpcCard.NpcRole.ACCOMPLICE]
		if subject_card.apparent_role in bad_roles:
			if subject_card.apparent_role == subject_card.actual_role:
				evidence_malus -= 2
			elif not subject_card.actual_role in bad_roles:
				evidence_malus += 1

	if evidence_malus != 0:
		bonus_malus += evidence_malus
		print("evidence bonus/malus: %s" % evidence_malus)

	# roll the die for the player

	var max_roll = roundi((attrs.PHY + 2 * attrs.MEN + attrs.HEA) / 4.0)
	print("max roll: %s" % max_roll)
	var actual_roll = randi_range(1, 10)
	print("actual roll: %s" % actual_roll)
	var net_roll = actual_roll + bonus_malus
	print("with bonus/malus: %s" % net_roll)

	# roll the die for the NPC

	var npc_max_roll = roundi((npc.physical + 2 * npc.mental + npc.health) / 4.0)
	print("NPC max roll: %s" % npc_max_roll)
	var npc_actual_roll = randi_range(1, 10)
	print("NPC actual roll: %s" % npc_actual_roll)
	var npc_net_roll = npc_actual_roll + attrs.get_npc_bonus_malus(npc)
	if npc.next_dialogue_malus > 0:
		npc_net_roll += npc.next_dialogue_malus
		print("NPC escape malus: %s" % npc.next_dialogue_malus)
		npc.next_dialogue_malus = 0
	if npc.actual_role == NpcCard.NpcRole.WITNESS:
		npc_net_roll += 1
		print("NPC witness malus: 1")
	print("NPC roll with bonus/malus: %s" % npc_net_roll)

	var tweak_attr = func(who, value) -> StringName:
		match randi() % 5:
			0, 1, 2:
				who.mental += value
				return &"MEN"
			3:
				who.physical += value
				return &"PHY"
			_:
				who.health += value
				return &"HEA"

	var success = false
	var critical_attr: StringName
	var rep_delta = 0

	if actual_roll == 10:
		critical_attr = tweak_attr.call(player, -1)
		if npc_actual_roll == 10:
			print("critical failure: update %s" % critical_attr)
		else:
			player.improve_emotion(-1)
			rep_delta -= 1
			print("critical failure: update Emo, Rep, %s" % critical_attr)
	elif actual_roll == 1:
		critical_attr = tweak_attr.call(player, 1)
		if npc_actual_roll == 1:
			print("critical success: update %s" % critical_attr)
		else:
			player.improve_emotion(1)
			print("critical success: update Emo, %s" % critical_attr)

	if npc_actual_roll == 10:
		var npc_critical_attr = tweak_attr.call(npc, -1)
		if actual_roll == 10:
			print("NPC critical failure: update %s" % npc_critical_attr)
		else:
			rep_delta += 1
			print("NPC critical failure: update Rep, %s" % npc_critical_attr)
	elif npc_actual_roll == 1:
		var npc_critical_attr = tweak_attr.call(npc, 1)
		if actual_roll == 1:
			print("NPC critical success: update %s" % npc_critical_attr)
		else:
			rep_delta -= 1
			print("NPC critical success: update Rep, %s" % npc_critical_attr)

	var net_margin = -1
	var infos_found = 0
	var express_doubt = false

	if actual_roll > 1 and npc_actual_roll == 1:
		print("failure due to NPC's critical success")
	else:
		var margin = max_roll - net_roll
		var npc_margin = npc_max_roll - npc_net_roll
		net_margin = margin - npc_margin
		print("player success margin: %s" % margin)
		print("NPC success margin: %s" % npc_margin)
		print("net success margin: %s" % net_margin)
		if actual_roll == 1 or net_margin >= 0:
			success = true

	# if successful, NPC may reveal bits of information

	if net_margin >= 0:
		var ret = _get_info_from_npc(npc, net_margin, subject_card)
		infos_found = ret[0]
		express_doubt = ret[1]

	# adjust player's attributes depending on bonus/malus from played cards

	var other_bonus_malus = attrs.get_post_bonus_malus(success)
	for key in other_bonus_malus:
		match key:
			"PHY":
				var delta: int = 0
				for value in other_bonus_malus[key]:
					delta += value
				player.physical += delta
				print("post bonus/malus %s: %s" % [key, delta])
			"MEN":
				var delta: int = 0
				for value in other_bonus_malus[key]:
					delta += value
				player.mental += delta
				print("post bonus/malus %s: %s" % [key, delta])
			"Rep":
				var delta: int = 0
				for value in other_bonus_malus[key]:
					delta += value
				rep_delta += delta
				print("post bonus/malus %s: %s" % [key, delta])
			"money":
				var delta: int = 0
				for value in other_bonus_malus[key]:
					delta += value
				delta *= maxi(1, get_current_case().get_difficulty())
				player.money += delta
				print("post bonus/malus %s: %s" % [key, delta])
			_:
				for value in other_bonus_malus[key]:
					print("post bonus/malus %s: %d" % [key, value])

	if npc.is_asleep():
		rep_delta -= 1
		print("NPC was sleeping: Rep -1")

	if rep_delta != 0:
		var old_rep = npc.player_reputation
		npc.player_reputation += rep_delta
		var actual_delta = npc.player_reputation - old_rep
		if absi(actual_delta) > 1 and npc.npc_status != NpcCard.NpcStatus.JAIL:
			await Globals.dialog_overlay.show_rep_message(actual_delta > 0)

	# this means the NPC's Wanted level increased to 5 after the preceding
	# combat, but he couldn't be sent to jail before the ensuing dialogue

	if _current_interaction_do_not_kill:
		await Globals.dialog_overlay.announce_prison_for_wanted(false)

	if player.health > 0:
		if actual_roll == 10:
			await Globals.dialog_overlay.show_player_improvement(-1)
		elif actual_roll == 1:
			await Globals.dialog_overlay.show_player_improvement(1, critical_attr)
		await Globals.dialog_overlay.show_dialogue_result(
			success, infos_found, express_doubt)

	# player's status (health, etc.) will be checked in end_interaction()
	await _increment_time(2, false)
	player.pass_time(2)

	_discard_cards(cards_played, success)
	return InteractionOutcome.SUCCESS if success else InteractionOutcome.FAILURE

##
## Starts a combat interaction when the player is attacked by a minion. This is
## a couroutine to be awaited, only because it displays a message first.
##
func start_minion_attack():
	var case = get_current_case()
	if case:
		var minion: NpcCard = case.fetch_minion()
		player.paranoia_state.minion_attack_count += 1
		await Globals.dialog_overlay.show_attack_message(minion)
		start_combat(minion, _player_location, _player_location_card)

##
## Starts a combat interaction: picks the fallback cards for the combat, saves
## the state of the cards in the Main scene (before we switch to the Interaction
## scene), and emits an interaction_started() signal telling The Game to switch
## scenes.
##
func start_combat(
		npc: NpcCard, location: PlayerLocation, location_card: LocationCard):
	player.pick_combat_cards(npc.actual_role == NpcCard.NpcRole.MINION)
	_current_interaction = InteractionType.COMBAT
	_current_interaction_location = location
	_current_interaction_location_card = location_card
	_current_interaction_npc = npc
	_push_card_state()
	save_game()
	interaction_started.emit()

#
# Rolls the dice for a combat. Returns CONTINUE if a dialogue will follow the
# combat, that is, if the player played a Do Not Kill card and was "successful",
# meaning either he rolled a 1 (critical success) or his roll was good enough to
# do some damage.
#
func _play_combat(cards_played: Array[Card]) -> InteractionOutcome:
	var npc: NpcCard = _current_interaction_npc
	var loc_name: String
	if _current_interaction_location == PlayerLocation.OTHER:
		loc_name = _current_interaction_location_card.get_display_name()
	else:
		loc_name = PlayerLocation.keys()[_current_interaction_location].capitalize()
	print("\n*** combat: %s with %s ***" % [loc_name, npc.get_display_name()])
	print("player attributes at start: MEN %d, PHY %d, HEA %d"
		  % [player.mental, player.physical, player.health])

	# roll the die for the player

	var attrs: InteractionAttributes = _play_cards(cards_played)
	var bonus_malus = attrs.get_bonus_malus()
	var rep = npc.player_reputation
	if rep != 0:
		bonus_malus -= rep
		print("Rep bonus/malus: %s" % -rep)
	var max_roll = roundi((attrs.PHY * 2 + attrs.MEN + attrs.HEA) / 4.0)
	print("max roll: %s" % max_roll)
	var actual_roll = randi_range(1, 10)
	print("actual roll: %s" % actual_roll)
	var net_roll = actual_roll + bonus_malus
	print("with bonus/malus: %s" % net_roll)

	# roll the die for the NPC

	var npc_max_roll = roundi((npc.physical + 2 * npc.mental + npc.health) / 4.0)
	print("NPC max roll: %s" % npc_max_roll)
	var npc_actual_roll = randi_range(1, 10)
	print("NPC actual roll: %s" % npc_actual_roll)
	var npc_net_roll = npc_actual_roll + attrs.get_npc_bonus_malus(npc)
	print("NPC roll with bonus/malus: %s" % npc_net_roll)

	# check for critical failures and successes, and calculate the damage done
	# by each combattant

	var tweak_attr = func(who, value) -> StringName:
		match randi() % 5:
			0, 1, 2:
				who.physical += value
				return &"PHY"
			3:
				who.mental += value
				return &"MEN"
			_:
				who.health += value
				return &"HEA"

	var critical_attr: StringName
	var damage: int = 0
	var npc_damage: int = 0

	if max_roll > net_roll:
		npc_damage = roundi((max_roll - net_roll) / 2.0)

	if npc_max_roll > npc_net_roll:
		damage = roundi((npc_max_roll - npc_net_roll) / 2.0)

	if actual_roll == 10:
		critical_attr = tweak_attr.call(player, -1)
		player.improve_emotion(-1)
		damage += 1
		print("critical failure: update Emo, %s" % critical_attr)
	elif actual_roll == 1:
		critical_attr = tweak_attr.call(player, 1)
		player.improve_emotion(1)
		npc_damage += 1
		print("critical success: update Emo, %s" % critical_attr)

	if npc_actual_roll == 10:
		var npc_critical_attr = tweak_attr.call(npc, -1)
		npc_damage += 1
		print("NPC critical failure: update %s" % npc_critical_attr)
	elif npc_actual_roll == 1:
		var npc_critical_attr = tweak_attr.call(npc, 1)
		player.improve_emotion(-1)
		damage += 1
		print("NPC critical success: update %s and player Emo" % npc_critical_attr)

	# check for combat cards with damage adjustment

	if damage > 0:
		var damage_adjust: int = 0
		var other_bonus_malus = attrs.get_post_bonus_malus()
		for value in other_bonus_malus.get("damage", []):
			damage_adjust += value
		print("player damage adjustment: %s" % damage_adjust)
		damage = maxi(0, damage + damage_adjust)

	# the player cannot die if he had a critical success

	if actual_roll == 1:
		damage = mini(damage, player.health - 1)

	# if the player played a Do Not Kill card, the NPC cannot die, and the
	# player receives a bonus for the ensuing dialogue (but you can't talk to a
	# minion)

	var do_not_kill = false

	if npc.actual_role != NpcCard.NpcRole.MINION:
		for card in cards_played:
			if card is CombatCard and card.is_do_not_kill():
				do_not_kill = true
				break

	if do_not_kill and npc_damage > 0:
		npc_damage = mini(npc_damage, npc.health - 1)
		player.next_dialogue_bonus_malus = -1

	print("player inflicts %d damage point(s) on NPC" % npc_damage)
	print("NPC inflicts %d damage point(s) on player" % damage)

	player.health -= damage
	npc.health -= npc_damage
	npc.player_reputation -= 2
	var npc_jail = _increase_npc_wanted(npc)
	save_game()

	if player.health > 0:
		if actual_roll == 10:
			await Globals.dialog_overlay.show_player_improvement(-1)
		elif actual_roll == 1:
			await Globals.dialog_overlay.show_player_improvement(1, critical_attr)

		var player_damage: CombatDamage
		var npc_state: NpcCombatState
		var is_minion: bool = npc.actual_role == NpcCard.NpcRole.MINION

		if actual_roll == 10 or npc_actual_roll == 1:
			player_damage = CombatDamage.CRITICAL_HIT
		elif damage > 0:
			player_damage = CombatDamage.HIT
		else:
			player_damage = CombatDamage.NONE

		if npc.health <= 0:
			npc_state = NpcCombatState.DEAD
		elif do_not_kill and (actual_roll == 1 or net_roll <= max_roll):
			npc_state = NpcCombatState.WILL_TALK
		else:
			npc_state = NpcCombatState.ESCAPED

		var body_search = await Globals.dialog_overlay.show_combat_result(
			player_damage, npc_state)

		if is_minion:
			if npc.health <= 0 or npc_jail:
				get_current_case().forget_minion()
			if body_search and randi() % 10 == 0:
				_reveal_culprit()

	# don't send the non-minion NPC to jail until AFTER the ensuing dialogue!

	if npc_jail:
		if do_not_kill:
			_current_interaction_do_not_kill = true
		else:
			await Globals.dialog_overlay.announce_prison_for_wanted(false)


	# player's status (health, wanted, etc.) will be checked in
	# end_interaction()

	await _increment_time(2, false)
	player.pass_time(2)

	if actual_roll == 10 or net_roll > max_roll:
		_discard_cards(cards_played, false)
		return InteractionOutcome.FAILURE
	else:
		_discard_cards(cards_played, true)
		return InteractionOutcome.CONTINUE if do_not_kill else InteractionOutcome.SUCCESS

##
## Called when the player has clicked on the OK button in the Interaction scene
## to proceed with (that is, roll the dice for) the current interaction. All the
## game logic is performed, the current interaction is reset, and the state of
## the cards is restored before we switch from the Interaction scene back to the
## Main scene.
##
## The outcome returned is usually either FAILURE or SUCCESS, but CONTINUE is
## returned in one case only: if the interaction was a combat, and if the player
## played a Do Not Kill card (and was not killed himself), so that a dialogue
## with the NPC may ensue. In that case, since we will be staying in the
## Interaction scene rather than switching to the Main scene, the state of the
## cards for Main is NOT restored yet.
##
func end_interaction(cards_played: Array[Card] = []) -> InteractionOutcome:
	var outcome = InteractionOutcome.FAILURE

	# reset the current interaction type immediately, so that the interaction
	# will not be played again if the user interrupts the game, but leave the
	# other interaction state variables, for now, so that they can be queried

	var interaction_type = _current_interaction
	_current_interaction = InteractionType.NONE

	match interaction_type:
		InteractionType.INVESTIGATION:
			outcome = await _play_investigation(cards_played)
			if not _pop_card_state():
				push_error("failed to restore card state at end of investigation")
		InteractionType.DIALOGUE:
			outcome = await _play_dialogue(cards_played)
			if _current_interaction_npc:
				_current_interaction_npc.test_health()
			else:
				push_error("interaction is dialogue but there is no NPC")
			if not _pop_card_state():
				push_error("failed to restore card state at end of dialogue")
		InteractionType.COMBAT:
			outcome = await _play_combat(cards_played)
			if _current_interaction_npc:
				_current_interaction_npc.test_health()
			else:
				push_error("interaction is combat but there is no NPC")
			if outcome != InteractionOutcome.CONTINUE:
				if not _pop_card_state():
					push_error("failed to restore card state at end of combat")

	player.clear_fallback_cards()
	_reset_interaction()

	await _check_player_status()
	if player.health > 0:
		save_game()
	else:
		if outcome == InteractionOutcome.CONTINUE:
			_pop_card_state()
		outcome = InteractionOutcome.FAILURE

	return outcome

func get_current_interaction() -> InteractionType:
	return _current_interaction

func get_current_interaction_location() -> PlayerLocation:
	return _current_interaction_location

func get_current_interaction_location_card() -> LocationCard:
	return _current_interaction_location_card

func get_current_interaction_npc() -> NpcCard:
	return _current_interaction_npc

func get_current_case() -> Case:
	if _current_case_index >= 0:
		return cases[_current_case_index]
	else:
		return null

##
## Sets the current case, making it active. If there is already a current case,
## that case is paused.
##
func set_current_case(index: int):
	if _current_case_index != index:
		if _current_case_index >= 0 and _current_case_index < cases.size():
			cases[_current_case_index].pause()
		_current_case_index = index
		if _current_case_index >= 0 and _current_case_index < cases.size():
			cases[_current_case_index].start()
		case_changed.emit()
		save_game()

#
# Returns the index of the paused case which will expire next, or -1 if there
# are no paused cases.
#
func _find_next_case() -> int:
	var next_case = -1
	var days_left = -1
	for index in cases.size():
		var case = cases[index]
		if case.get_status() == Case.Status.PAUSED:
			var d = case.get_days_left()
			if next_case < 0 or days_left > d:
				next_case = index
				days_left = d
	return next_case

#
# Closes the current case, if there is one.
#
func _close_current_case():
	if _current_case_index >= 0:
		_close_case(_current_case_index)

#
# Closes the given case. If the index given is that of the current case, the
# paused case which will expire next is made the current case.
#
func _close_case(index: int):
	if index == _current_case_index:
		set_current_case(-1)
		_delete_case(index)
		set_current_case(_find_next_case())
	else:
		_delete_case(index)
	save_game()

func _delete_case(index: int):
	cases[index].close()
	cases.remove_at(index)
	if _current_case_index > index:
		_current_case_index -= 1

func _open_final_case():
	_close_current_case()
	while cases.size() > 0:
		_delete_case(cases.size() - 1)
	cases.append(Case.generate(true))
	set_current_case(0)

##
## Returns the index in the case list of the given case.
##
func find_case(case: Case) -> int:
	return cases.find(case)

##
## Returns a list of all open cases (active or paused).
##
func get_open_cases() -> Array[Case]:
	var ret: Array[Case]
	for case in cases:
		if case.get_status() in [Case.Status.ACTIVE, Case.Status.PAUSED]:
			ret.append(case)
	return ret

##
## Moves the player to the given location, if he is not there already. If
## location is PlayerLocation.OTHER, then a LocationCard must be given. The
## trip to any location takes an hour.
##
## Returns true if the player is already at the given location or if the move
## goes as planned, false if the player is attacked by a minion en route.
##
## If the player does change location, a location_changed() signal is emitted.
##
## Note that this is a coroutine to be awaited, and it is possible the
## player may have died on return, or that the current case may have expired. It
## is also possible the player may be attacked by a minion, either at his
## current location (in which case he will not be moved) or at his destination.
##
func move_player_to(location: PlayerLocation, card: LocationCard = null) -> bool:
	if _player_location == location and _player_location_card == card:
		return true

	# check for a minion attack and do it now, unless the player is still at the
	# office or in prison

	var case = get_current_case()
	var minion_attack = case and case.check_minion_attack()
	if minion_attack and not _player_location in [
		PlayerLocation.OFFICE, PlayerLocation.PRISON
	]:
		await start_minion_attack()
		return false

	await _pass_one_hour_private()

	# it is possible that, in the hour that just passed, the current case
	# expired, in which case the location card may not exist anymore...
	if card == null or is_instance_valid(card):
		set_player_location(location, card)

	# do the minion attack now, if the player is no longer at the office or in
	# prison

	if minion_attack and not _player_location in [
		PlayerLocation.OFFICE, PlayerLocation.PRISON
	]:
		await start_minion_attack()
		return false

	return true

##
## Changes the player's location. If location is PlayerLocation.OTHER, then a
## LocationCard must be given. Returns false if the player is already at the
## given location, otherwise emits a location_changed() signal and returns true.
##
func set_player_location(location: PlayerLocation, card: LocationCard = null) -> bool:
	if _player_location == location and _player_location_card == card:
		return false
	_player_location = location
	_player_location_card = card
	location_changed.emit()
	return true

##
## Returns the current location of the player. If it is PlayerLocation.OTHER,
## retrieve the exact location with get_player_location_card().
##
func get_player_location() -> PlayerLocation:
	return _player_location

##
## Returns the location card corresponding to the player's current location.
## Useful only if get_player_location() returns PlayerLocation.OTHER.
##
func get_player_location_card() -> LocationCard:
	return _player_location_card

#
# Returns true if the NPC runs away before a dialogue, false if he does not run
# away, or if he tries to run away but fails.
#
func _does_npc_run(npc: NpcCard) -> NpcEscapeOutcome:

	# in most cases he does not try

	if randi() % (2 * npc.mental) > 0:
		return NpcEscapeOutcome.STAYED

	# if he does want to try, roll the die...

	var max_roll = roundi((npc.physical + npc.mental + npc.health) / 3.0)
	var actual_roll = randi_range(1, 10)
	var net_roll = actual_roll + npc.get_wanted_malus()
	var success: bool

	var tweak_attr = func(value):
		match randi() % 5:
			0, 1, 2:
				npc.mental += value
			3:
				npc.physical += value
			4:
				npc.health += value

	if actual_roll == 10:
		# critical failure
		tweak_attr.call(-1)
		success = false
	elif actual_roll == 1:
		# critical success
		tweak_attr.call(1)
		success = true
	elif net_roll > max_roll:
		# normal failure
		success = false
	else:
		# normal success
		success = true

	if not success:
		npc.next_dialogue_malus = 1

	var npc_jail = false
	if npc.test_health() and success:
		npc_jail = _increase_npc_wanted(npc)

	save_game()

	if npc_jail:
		await Globals.dialog_overlay.announce_prison_for_wanted(false)
	else:
		await Globals.dialog_overlay.show_npc_run(success)

	return NpcEscapeOutcome.SUCCEEDED if success else NpcEscapeOutcome.FAILED

func _increase_npc_wanted(npc: NpcCard) -> bool:
	if npc.wanted < 4:
		npc.wanted += 1
		return false
	else:
		npc.npc_status = NpcCard.NpcStatus.JAIL
		return true

#
# The chances of the NPC attacking the player before a dialogue depend on
# whether the player has met him before, his reputation, the number of
# incriminating links the player has established, and the difficulty of the
# case.
#
func _does_npc_attack(npc: NpcCard) -> bool:
	var percent = 0

	match npc.player_reputation:
		-2:
			percent += 5
		-1:
			percent += 2
		1:
			percent -= 2
		2:
			percent -= 5

	var case: Case = get_current_case()
	var full_link_count: int = 0
	var dotted_link_count: int = 0

	for link in case.get_links():
		if link.is_incriminating():
			if link.status == Link.Status.CONFIRMED:
				full_link_count += 1
			else:
				dotted_link_count += 1

	if full_link_count + dotted_link_count > 0:
		if full_link_count == 0:
			percent += 1
		elif dotted_link_count > full_link_count:
			percent += 3
		else:
			percent += 5

	percent *= case.get_difficulty()

	if npc.actual_role == NpcCard.NpcRole.VICTIM:
		percent *= 0.25

	return randi_range(1, 100) <= percent

#
# Adds a piece of information to the given list if it is not already there, and
# if it is not yet known to the player. Special case: if the information is to
# be revealed by the given NPC, then it may be revealed again (i.e. confirmed),
# unless it has already been revealed by the same NPC.
#
func _add_info_to_reveal(
	infos: Array[InfoToReveal], card1: Card, card2: Card, type: Link.Type,
	revealer: NpcCard = null):

	var link = card1.find_link_to(card2, type)
	if link and (revealer == null or revealer in link.sources):
		return

	var new_info = InfoToReveal.new(card1, card2, type)
	for old_info in infos:
		if old_info.compare(new_info):
			return
	infos.append(new_info)

#
# Returns true if the given NPC is qualified to reveal the hideout of another
# NPC.
#
func _npc_can_reveal_hideout_of_other_npc(npc: NpcCard, other: NpcCard) -> bool:
	return (npc == other
			or npc.get_connection_to(other) in [
				Link.Type.SPOUSE,
				Link.Type.INTIMACY,
				Link.Type.FRIEND,
				Link.Type.ENEMY,
				Link.Type.ACQUAINTANCE
			])

#
# Adds every piece of information known about the "subject" NPC to the given
# list, if the information is not there already. The subject's hideout can be
# revealed only if the NPC talking (the "revealer") if hidden_info_ok is true,
# the revealer is close enough to the subject.
#
func _add_all_known_info_about_npc(
	infos: Array[InfoToReveal], revealer: NpcCard, subject: NpcCard,
	hidden_info_ok: bool):

	# where the NPC lives, works, hangs out and hides out
	
	for link_type in [Link.Type.HOME, Link.Type.WORK, Link.Type.HANGOUT]:
		for loc in subject.get_connections(link_type):
			_add_info_to_reveal(infos, subject, loc, link_type)

	if (hidden_info_ok and
		_npc_can_reveal_hideout_of_other_npc(revealer, subject)):
		var hideout = subject.get_one_connection(Link.Type.HIDEOUT)
		if hideout:
			_add_info_to_reveal(infos, subject, hideout, Link.Type.HIDEOUT)

	# what other NPCs the NPC is linked to

	for link_type in _npc_link_types:
		for other_npc in subject.get_connections(link_type):
			_add_info_to_reveal(infos, subject, other_npc, link_type)

	# objects belonging to the NPC

	for obj in subject.get_connections(Link.Type.PROPERTY):
		_add_info_to_reveal(infos, subject, obj, Link.Type.PROPERTY)

#
# Reveals new information from an NPC after a successful dialogue. Returns a
# tuple containing the number of pieces of information that were revealed and
# a bool which is true if the player may be permitted to doubt the veracity of
# the information.
#
func _get_info_from_npc(
	npc: NpcCard, margin: int, subject_card: Card) -> Array:

	if margin < 0:
		return [0, false]

	var info_count = maxi(1, roundi(margin / 2.0))
	var hidden_info_ok = margin >= 2

	# look at information about the object, place or NPC the player asked about

	var candidates: Array[InfoToReveal]
	var revealed: Array[InfoToReveal]

	match subject_card.get_card_type():
		Card.CardType.OBJECT:

			# the object's owner(s), if the NPC knows them

			for obj_owner in subject_card.get_connections(Link.Type.PROPERTY):
				if obj_owner == npc or obj_owner in npc.get_all_npc_connections():
					_add_info_to_reveal(
						candidates, obj_owner, subject_card, Link.Type.PROPERTY, npc)
					break

		Card.CardType.LOCATION:
			var npcs_at_location = subject_card.get_all_npc_connections()
			if npc in npcs_at_location:

				# known NPCs who live, work, hang out or hide out at the
				# location

				var known_npcs = npc.get_all_npc_connections()
				for npc_at_location in npcs_at_location:
					if npc_at_location == npc or npc_at_location in known_npcs:
						var link_type = npc_at_location.get_connection_to(subject_card)
						if (link_type != Link.Type.HIDEOUT
							or (hidden_info_ok and
								_npc_can_reveal_hideout_of_other_npc(npc, npc_at_location))):
							_add_info_to_reveal(
								candidates, npc_at_location, subject_card, link_type, npc)

				# objects found at the location

				for obj in subject_card.get_connections(Link.Type.FOUND):
					if obj is ObjectCard:
						_add_info_to_reveal(
							candidates, obj, subject_card, Link.Type.FOUND, npc)

		Card.CardType.NPC:

			# everything that can be revealed about the NPC

			if subject_card == npc or npc in subject_card.get_all_npc_connections():
				_add_all_known_info_about_npc(
					candidates, npc, subject_card, hidden_info_ok)

	while candidates.size() > 0 and revealed.size() < info_count:
		var index = randi() % candidates.size()
		revealed.push_back(candidates.pop_at(index))

	# turn some of the information into misinformation, maybe...
	# how likely is this NPC to lie?

	var normal_lie_prob: float
	var incriminating_lie_prob: float
	var express_doubt: bool = false

	match npc.actual_role:
		NpcCard.NpcRole.CULPRIT:
			normal_lie_prob = (5.0 + npc.mental) / (45.0 + npc.mental)
			incriminating_lie_prob = (6.0 + npc.mental) / (30.0 + npc.mental)
		NpcCard.NpcRole.ACCOMPLICE:
			normal_lie_prob = (3.0 + npc.mental) / (54.0 + npc.mental)
			incriminating_lie_prob = (7.0 + npc.mental) / (42.0 + npc.mental)
		_:
			normal_lie_prob = (1.0 + npc.mental) / (60.0 + npc.mental)
			incriminating_lie_prob = normal_lie_prob

	# for each piece of information, roll the dice to see if the NPC lies and,
	# if the roll is borderline, express doubt about the NPC's honesty

	var is_lie: Array[bool]

	for i in revealed.size():
		var info: InfoToReveal = revealed[i]
		var lie_prob: float
		if Link.is_type_incriminating(info.link_type):
			lie_prob = incriminating_lie_prob
		else:
			lie_prob = normal_lie_prob
		var roll = randf()
		if roll > lie_prob * 0.8 and roll < lie_prob * 1.2:
			express_doubt = true
		if roll < lie_prob and _distort_info(
			revealed, i, npc, subject_card if subject_card else npc):
			is_lie.append(true)
		else:
			is_lie.append(false)

	# reveal cards that are hidden and create new links

	var case = get_current_case()

	for i in revealed.size():
		var info: InfoToReveal = revealed[i]
		print("discovered %s: %s <=> %s (%s)" % [
			Link.Type.keys()[info.link_type].capitalize(),
			info.card1.get_display_name(),
			info.card2.get_display_name(),
			"a lie" if is_lie[i] else "true"])
		_reveal_card(info.card1)
		_reveal_card(info.card2)
		var link = info.card1.find_link_to(info.card2, info.link_type)
		if link:
			link.needs_attention = true
			if link.sources:
				link.is_repeated = true
		else:
			link = case.create_link(
				info.card1, info.card2, info.link_type, false, true)
			if (info.card1.reveal_status == Card.RevealStatus.REVEALED and
				info.card2.reveal_status == Card.RevealStatus.REVEALED):
				link.needs_attention = true
		link.sources.append(npc)

	return [revealed.size(), express_doubt]

#
# Tries to distort one piece of information in the given array to something
# similar but different and plausible. Returns true on success.
#
func _distort_info(
	all_info: Array[InfoToReveal], which_info: int, speaker: NpcCard,
	subject: Card) -> bool:
	var info: InfoToReveal = all_info[which_info]
	var lies: Array[InfoToReveal]

	# invent possible lies
	
	var npc_pool: Array[NpcCard] = speaker.get_all_npc_connections()
	npc_pool.append(speaker)

	# connection between two NPCs: we can change the nature of the connection,
	# or change one of the NPCs to another NPC that the speaker knows

	if info.link_type in _npc_link_types:
		for other_type in _npc_link_types:
			if other_type != info.link_type:
				lies.append(
					InfoToReveal.new(info.card1, info.card2, other_type))
		for npc in npc_pool:
			if not npc in [info.card1, info.card2]:
				if info.card2 in [speaker, subject] or npc in [speaker, subject]:
					lies.append(	InfoToReveal.new(npc, info.card2, info.link_type))
				if info.card1 in [speaker, subject] or npc in [speaker, subject]:
					lies.append(	InfoToReveal.new(info.card1, npc, info.link_type))

	# an NPC's hangout: we can change the NPC to another NPC that the speaker
	# knows, or change the hangout to another place

	elif info.link_type == Link.Type.HANGOUT:
		var npc: NpcCard
		var hangout: LocationCard

		if info.card1 is NpcCard:
			npc = info.card1
			hangout = info.card2
		else:
			npc = info.card2
			hangout = info.card1

		# if the player asked about the location, change the NPC; if he asked
		# about the NPC, change the location

		if subject == npc:
			for loc in get_current_case().get_all_potential_hangouts():
				if loc != hangout:
					lies.append(	InfoToReveal.new(npc, loc, Link.Type.HANGOUT))
		elif subject == hangout:
			for other_npc in npc_pool:
				if other_npc != npc:
					lies.append(
						InfoToReveal.new(other_npc, hangout, Link.Type.HANGOUT))

	# who (or what location) an object belongs to: we can change the NPC owner
	# to another NPC that the speaker knows (unless the player asked about the
	# owner specifically), but not the object itself

	elif info.link_type == Link.Type.PROPERTY:
		var obj_owner: NpcCard
		var obj: ObjectCard
		if info.card1 is NpcCard:
			obj_owner = info.card1
			obj = info.card2
		elif info.card2 is NpcCard:
			obj_owner = info.card2
			obj = info.card1
		if obj_owner and subject == obj:
			for npc in npc_pool:
				if npc != obj_owner:
					lies.append(InfoToReveal.new(npc, obj, Link.Type.PROPERTY))

	# pick a lie at random which is not a duplicate of an existing link or of
	# another piece of information we are about to reveal

	while lies.size() > 0:
		var which_lie: int = randi() % lies.size()
		var lie: InfoToReveal = lies.pop_at(which_lie)
		var is_duplicate = false

		if lie.card1 in lie.card2.find_linked_cards(lie.link_type):
			is_duplicate = true
		else:
			for i in all_info.size():
				if i != which_info and lie.compare(all_info[i]):
					is_duplicate = true
					break

		if not is_duplicate:
			all_info[which_info] = lie
			return true

	return false

#
# Selects discoveries at random (NPCs or objects) from the given location.
# evidence_count is the maximum number of pieces of evidence that the player may
# find; total_count is the maximum number of objects that he may find, whether
# actual evidence or not. Returns how many pieces of information were revealed.
#
func _get_unknown_connections_to_location(
	location: LocationCard, evidence_count: int, total_count: int) -> int:

	var case: Case = get_current_case()

	# objects that are evidence
	var evidence = []

	# useless objects and NPCs
	var others = []

	# unknown NPCs associated with the location, and known NPCs whose
	# connections to the location have not all been revealed

	for npc in location.get_all_npc_connections():
		if npc.reveal_status == Card.RevealStatus.HIDDEN:
			others.append(npc)
		else:
			for link_type in npc.get_all_connections_to(location):
				if not location in npc.find_linked_cards(link_type):
					others.append(npc)
					break

	# unknown objects associated with the location

	for obj in location.get_all_object_connections():
		if obj.reveal_status == Card.RevealStatus.HIDDEN:
			if obj in case.evidence:
				var array = evidence if obj in case.evidence else others
				array.append(obj)

	# first choose pieces of evidence at random, if the player has earned it

	var cards: Array[Card]

	while evidence_count > 0 and not evidence.is_empty():
		var obj = evidence.pick_random()
		cards.append(obj)
		evidence.erase(obj)
		evidence_count -= 1
		total_count -= 1

	# then choose other things at random (NPCs and/or useless objects)

	while total_count > 0 and not others.is_empty():
		var card = others.pick_random()
		cards.append(card)
		others.erase(card)
		total_count -= 1

	# reveal the new cards and appropriate links

	for card in cards:
		print("discovered ", card.get_display_name())
		_reveal_card(card)
		if card is NpcCard:
			case.add_links_between_npc_and_location(card, location)
		elif card is ObjectCard:
			for obj_owner in card.get_connections(Link.Type.PROPERTY):
				if obj_owner == location or obj_owner.get_connection_to(location) >= 0:
					_reveal_card(obj_owner)
					case.create_link(obj_owner, card, Link.Type.PROPERTY, false, true)
					if obj_owner is NpcCard:
						case.add_links_between_npc_and_location(obj_owner, location)

	return cards.size()

#
# Reveals the given card, if it has not already been revealed, as well as some
# information about the object, location or NPC that is revealed automatically.
#
func _reveal_card(card: Card):
	if card.reveal_status != Card.RevealStatus.HIDDEN:
		return
	card.reveal_status = Card.RevealStatus.LIMBO

	var case: Case = get_current_case()

	match card.get_card_type():
		Card.CardType.OBJECT:
			if card.get_owner_reveal():
				for obj_owner in card.get_connections(Link.Type.PROPERTY):
					_reveal_card(obj_owner)
					case.create_link(
						obj_owner, card, Link.Type.PROPERTY, true, true)
			var location = card.get_location()
			if location:
				_reveal_card(location)
				case.create_link(location, card, Link.Type.FOUND, true, true)

		Card.CardType.LOCATION:
			for resident in card.get_connections(Link.Type.HOME):
				_reveal_card(resident)
				case.create_link(resident, card, Link.Type.HOME, true, true)
			card.display_name_changed()

		Card.CardType.NPC:
			var home = card.get_home()
			if home:
				_reveal_card(home)
				case.create_link(card, home, Link.Type.HOME, true, true)
				home.display_name_changed()
			var partner = card.get_spouse()
			if partner and partner.reveal_status != Card.RevealStatus.HIDDEN:
				case.create_link(card, partner, Link.Type.SPOUSE, true, true)

#
# Creates a link, or highlights an existing link, between a culprit and a
# victim.
#
func _reveal_culprit():
	var case: Case = get_current_case()
	if case == null:
		return

	# which culprit to reveal? and which victim to link to?

	var victims: Array[NpcCard]
	var culprits: Array[NpcCard]

	for npc in case.npcs:
		match npc.actual_role:
			NpcCard.NpcRole.VICTIM:
				victims.append(npc)
			NpcCard.NpcRole.CULPRIT:
				culprits.append(npc)

	if not (victims and culprits):
		return

	var victim: NpcCard = victims.pick_random()
	var culprit: NpcCard = culprits.pick_random()

	# find existing link or create a new one

	var link: Link = victim.find_link_to(culprit, Link.Type.GUILT)
	if link:
		link.status = Link.Status.CONFIRMED
	else:
		link = case.create_link(victim, culprit, Link.Type.GUILT, false, true)
	link.needs_attention = true
	culprit.apparent_role = NpcCard.NpcRole.CULPRIT

#
# Checks for a paranoia attack, if the player isn't already paranoid. In case of
# a paranoia attack, switches the game to paranoia mode: any open cases are
# abandoned and replaced by the "final case", the player no longer sleeps or
# takes drugs, etc. This is a coroutine to be awaited.
#
func _check_for_paranoia_attack() -> bool:
	if not player.update_paranoia():
		return false

	# tell the player he has lapsed into paranoia; the paranoia() signal causes
	# the motive list in the main scene to be updated accordingly

	paranoia.emit()
	await Globals.dialog_overlay.announce_paranoia()

	# close all cases and open the new, final case

	_open_final_case()

	return true

##
## Takes the player to the investigation center, where his solution to the
## current case is validated or invalidated.
##
## Note that this is a coroutine to be awaited, and on return the player may
## have died, or may no longer have a current case.
##
func validate_case():
	var case = get_current_case()

	# the "final" case can never be validated!

	if case and case.is_final():
		died.emit()
		return

	# try to get to the investigation center first

	if not (await move_player_to(PlayerLocation.INVESTIGATION_CENTER)
			and player.health > 0 and case):
		return

	var result: Case.SolutionResult = case.check_solution()
	var min_win: float
	var max_win: float
	var money_won: int = 0
	var cards_won: int = 0

	match Globals.game_difficulty:
		0, 1:
			min_win = 1.0
			max_win = 1.2
		3, 4:
			min_win = 0.8
			max_win = 1.0
		_:
			min_win = 0.9
			max_win = 1.1

	match result:
		Case.SolutionResult.WRONG:
			if player.emotion == 0:
				player.emotion = -1
			else:
				player.improve_emotion(-1)
			match randi() % 3:
				0:
					player.health -= 1
				1:
					player.mental -= 1
				2:
					player.physical -= 1
			player.paranoia_state.failed_case_count += 1
			await _check_for_paranoia_attack()

		Case.SolutionResult.HALF_RIGHT:
			money_won = roundi(
				100 * case.get_difficulty() * randf_range(min_win, max_win))
			cards_won = roundi((case.get_difficulty() + 1) * 0.5)
			player.improve_emotion(1)
			player.improve_addiction(1)
			player.wanted -= 1
			player.money += money_won

		Case.SolutionResult.RIGHT:
			money_won = roundi(
				100 * case.get_difficulty() * randf_range(min_win, max_win))
			cards_won = case.get_difficulty() + 1
			player.emotion = 0
			player.addiction = 0
			player.wanted = 0
			player.money += money_won

	await Globals.dialog_overlay.show_case_solved(result, money_won, cards_won)

	if cards_won > 0:
		player.award_new_cards(cards_won)
		await manage_cards()

	_close_current_case()
	if get_current_case() == null:
		await visit_investigation_center()

##
## Takes the player to the investigation center, where he is given the option to
## pay a fee and abandon his current case, if he has one, and if it is not too
## late.
##
## Note that this is a coroutine to be awaited, and on return the player may
## have died, or may no longer have a current case.
##
func abandon_case():
	if not (await move_player_to(PlayerLocation.INVESTIGATION_CENTER)
			and player.health > 0 and get_current_case()):
		return
	var fee = get_current_case().get_abandon_fee()
	if await Globals.dialog_overlay.abandon_case(fee):
		player.money -= fee
		player.paranoia_state.abandoned_case_count += 1
		_close_current_case()
		await _check_for_paranoia_attack()
		if get_current_case() == null:
			await visit_investigation_center()

##
## Takes the player to the office to manage his cases, and possibly switch to a
## previously paused case.
##
## Note that this is a coroutine to be awaited, and on return the player may
## have died, or may no longer have a current case.
##
func manage_cases():
	if await move_player_to(PlayerLocation.OFFICE) and player.health > 0:
		if await Globals.dialog_overlay.manage_cases():
			save_game()

##
## Returns true if the player has succumbed to paranoia and the "final" case is
## underway.
##
func is_final_case():
	var case = get_current_case()
	return case and case.is_final()

##
## Allows the player to manage his cards, potentially keeping newly earned cards
## and discarding others.
##
## Note that this is a coroutine to be awaited.
##
func manage_cards():
	if await Globals.dialog_overlay.manage_cards():
		save_game()

#
# Saves the visual state of all object, location and NPC cards that are visible
# to the player. This is done before switching from the main scene to the
# interaction scene so that, however the cards move around during the
# interaction, they can be put back where they were afterwards.
#
func _push_card_state():
	var case = get_current_case()
	if case:
		for card in case.get_revealed_cards():
			if card.get_card_type() in [
				Card.CardType.OBJECT, Card.CardType.LOCATION, Card.CardType.NPC
			]:
				card.push_state()

#
# Restores the visual state of all object, location and NPC cards after a
# previous call to _push_card_state(). This is done before switching back from
# the interaction scene to the main scene. Returns false if the card state
# cannot be restored correctly.
#
func _pop_card_state():
	var ok = true
	var case = get_current_case()
	if case:
		for card in case.get_revealed_cards():
			if card.get_card_type() in [
				Card.CardType.OBJECT, Card.CardType.LOCATION, Card.CardType.NPC
			]:
				if not card.pop_state():
					ok = false
	return ok

func save_game(binary: bool = false):
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		var dict = SaveLoadTools.save_to_json_dict(self)
		# NB. in a quick test, the binary file was bigger: 157 kb vs. 141 kb!
		if binary:
			file.store_var(dict)
		else:
			file.store_line(JSON.stringify(dict, "\t"))

func load_game():
	var json = FileAccess.get_file_as_string(_save_path)
	if json:
		var data = JSON.parse_string(json)
		if data and data is Dictionary:
			var obj = SaveLoadTools.restore_from_json_dict(data)
			if obj:
				assign(obj)

func assign(other: GameState):
	player = other.player
	cases = other.cases
	_hour = other._hour
	_random_sms_time = other._random_sms_time
	_last_new_case_day = other._last_new_case_day
	_last_doctor_day = other._last_doctor_day
	_last_dealer_day = other._last_dealer_day
	_dealer_drug_stock = other._dealer_drug_stock
	_last_crimes = other._last_crimes
	_current_case_index = other._current_case_index
	_player_location = other._player_location
	_player_location_card = other._player_location_card
	_current_interaction = other._current_interaction
	_current_interaction_location = other._current_interaction_location
	_current_interaction_location_card = other._current_interaction_location_card
	_current_interaction_npc = other._current_interaction_npc
	_current_interaction_bonus_malus = other._current_interaction_bonus_malus
	_current_interaction_do_not_kill = other._current_interaction_do_not_kill

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.GAME_STATE

#
# For save/load.
#
func get_unique_id():
	return "game"

#
# For save/load.
#
func get_referenced_objects():
	var refs = [player]
	for case in cases:
		refs.append(case)
	if _player_location_card:
		refs.append(_player_location_card)
	if _current_interaction_location_card:
		refs.append(_current_interaction_location_card)
	if _current_interaction_npc:
		refs.append(_current_interaction_npc)
	return refs

#
# For save/load.
#
func get_json_dict():
	var dict = {
		"player": player.get_unique_id(),
		"hour": _hour,
		"random_sms_time": _random_sms_time,
		"last_new_case_day": _last_new_case_day,
		"last_doctor_day": _last_doctor_day,
		"last_dealer_day": _last_dealer_day,
		"dealer_drug_stock": _dealer_drug_stock,
		"last_crimes": _last_crimes,
		"current_case_index": _current_case_index
	}

	if cases:
		var case_refs = []
		for case in cases:
			case_refs.append(case.get_unique_id())
		dict["cases"] = case_refs

	if _player_location != PlayerLocation.OFFICE:
		dict["player_location"] = _player_location
		if _player_location_card:
			dict["player_location_card"] = _player_location_card.get_unique_id()

	if _current_interaction != InteractionType.NONE:
		dict["interaction"] = _current_interaction
		if _current_interaction_location != PlayerLocation.OTHER:
			dict["interaction_location"] = _current_interaction_location
		if _current_interaction_location_card:
			dict["interaction_location_card"] = _current_interaction_location_card.get_unique_id()
		if _current_interaction_npc:
			dict["interaction_npc"] = _current_interaction_npc.get_unique_id()
		if _current_interaction_bonus_malus != 0:
			dict["interaction_bonus_malus"] = _current_interaction_bonus_malus
		if _current_interaction_do_not_kill:
			dict["interaction_do_not_kill"] = _current_interaction_do_not_kill

	return dict

#
# For save/load.
#
func restore(dict, catalog):
	_hour = dict.hour
	_random_sms_time = dict.get("random_sms_time", -1)
	_last_new_case_day = dict.get("last_new_case_day", -1)
	_last_doctor_day = dict.get("last_doctor_day", -1)
	_last_dealer_day = dict.get("last_dealer_day", -1)
	_dealer_drug_stock = dict.get("dealer_drug_stock", 0)
	_last_crimes.assign(dict.last_crimes)
	_current_case_index = dict.current_case_index
	player = catalog[dict.player]

	for case_ref in dict.get("cases", []):
		cases.append(catalog[case_ref])

	if "player_location" in dict:
		_player_location = dict.player_location
		if "player_location_card" in dict:
			_player_location_card = catalog[dict.player_location_card]

	if "interaction" in dict:
		_current_interaction = dict.interaction
		_current_interaction_location = dict.get("interaction_location", PlayerLocation.OTHER)
		if "interaction_location_card" in dict:
			_current_interaction_location_card = catalog[dict.interaction_location_card]
		if "interaction_npc" in dict:
			_current_interaction_npc = catalog[dict.interaction_npc]
		_current_interaction_bonus_malus = dict.get("interaction_bonus_malus", 0)
		_current_interaction_do_not_kill = dict.get("interaction_do_not_kill", false)

#
# For save/load.
#
func allocate() -> Object:
	return load("res://SCRIPTS/Game_State.gd").new()
