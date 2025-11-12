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

var player: Player = Player.new()
var cases: Array[Case]

## Price for a search warrant.
const warrant_price: int = 25

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

## Signal emitted when the player has died.
@warning_ignore("unused_signal")
signal died

## Signal emitted when the player starts an interaction.
signal interaction_started

var _combat_data = preload("res://JSON/INTERACTION/Combat.json").data
var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

# where game state is saved/reloaded
const _save_path = "user://game.sav"

# play starts at 8am Monday
const _start_time = 8

# hours passed since the first Monday at midnight
var _hour: int

# has the player visited the investigation center today?
var _has_visited_hub: bool

# the last day the player visited the doctor
var _last_doctor_day: int

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
var _current_interaction_location: LocationCard
var _current_interaction_npc: NpcCard
var _current_interaction_bonus_malus: int

func _ready():
	load_game()

func start_game():
	_hour = _start_time
	_has_visited_hub = false
	_last_doctor_day = -1
	_dealer_drug_stock = randi_range(5, 10)
	_last_crimes.clear()
	_current_case_index = -1
	_player_location = PlayerLocation.OFFICE
	_player_location_card = null
	_current_interaction = InteractionType.NONE
	_current_interaction_location = null
	_current_interaction_npc = null
	_current_interaction_bonus_malus = 0

	cases.clear()
	for i in 5:
		cases.append(Case.generate())

	player.start_game()

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
func get_day() -> int:
	@warning_ignore("integer_division")
	return _hour / 24

##
## Like get_day(), but considers that the day starts at 8 AM.
##
func get_working_day() -> int:
	@warning_ignore("integer_division")
	return (_hour - 8) / 24

##
## Returns the current time (hour), in the range 0-23.
##
func get_hour() -> int:
	return _hour % 24

##
## Returns the current time slot: morning, afternoon, evening or night; weekday
## or weekend.
##
func get_time_slot() -> TimeSlot:
	var hour = get_hour()
	var workday = get_working_day()
	if hour < 8 or hour >= 20:
		return TimeSlot.NIGHT if workday < 5 else TimeSlot.WE_NIGHT
	elif hour < 12:
		return TimeSlot.MORNING if workday < 5 else TimeSlot.WE_MORNING
	elif hour < 16:
		return TimeSlot.AFTERNOON if workday < 5 else TimeSlot.WE_AFTERNOON
	else:
		return TimeSlot.EVENING if workday < 5 else TimeSlot.WE_EVENING

func _get_weeks_passed() -> int:
	@warning_ignore("integer_division")
	return (_hour - _start_time) / (24 * 7)

#
# Increments the given time by the given number of hours. Note that this is a
# coroutine to be awaited, and also that the player may have died on return.
#
func _increment_time(hours: int):
	var day_before = get_working_day()
	_hour += hours
	var day_after = get_working_day()
	time_changed.emit()

	# TODO: if player has not slept for 24 hours, force him to take a day off
	# TODO: if wanted == 5, send player to prison
	# TODO: if player has 5 debts, send him to prison

	for day in range(day_before + 1, day_after + 1):
		_new_day(day)
		if not await player.test_health():
			died.emit()
			return

	save_game()

#
# Stuff that needs to be dealt with at the start of each new day.
#
func _new_day(day: int):

	# every Monday the player is sent a new bill, and Rowena replenishes her
	# stock of drugs

	if day % 7 == 0:
		_send_new_bill()
		_dealer_drug_stock = randi_range(5, 10)
	else:
		if _dealer_drug_stock > 0 and randi() % 4 == 0:
			_dealer_drug_stock -= 1

	# increment the health of NPCs in active cases

	for case in cases:
		if case.get_status() == Case.Status.ACTIVE:
			for npc in case.get_all_npcs():
				npc.new_day()

	# things the player can do only once a day

	_has_visited_hub = false
	player.new_day()

func _send_new_bill():
	for i in player.get_debt_count():
		var debt = player.get_debt(i)
		player.set_debt(i, roundi(debt * 1.1))

	var new_debt = 75
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
func pass_one_hour():
	player.pass_one_hour()
	await _increment_time(1)

##
## Takes the player back to the office, if he is not there already, then puts
## him to sleep for the given number of hours. Note that this is a coroutine to
## be awaited, and also that the player may wake up dead!
##
func sleep(hours: int):
	if _player_location != PlayerLocation.OFFICE:
		await pass_one_hour()
		set_player_location(PlayerLocation.OFFICE)
	await player.sleep(hours)
	await _increment_time(hours)

##
## Returns false if the player has already visited the Investigation Center
## today.
##
func can_visit_investigation_center() -> bool:
	return not _has_visited_hub

func visit_investigation_center():
	if _player_location != PlayerLocation.INVESTIGATION_CENTER:
		await pass_one_hour()
		set_player_location(PlayerLocation.INVESTIGATION_CENTER)
	_has_visited_hub = await Globals.dialog_overlay.open_investigation_center()

func visit_office():
	if _player_location != PlayerLocation.OFFICE:
		await pass_one_hour()
		set_player_location(PlayerLocation.OFFICE)
	await Globals.dialog_overlay.open_office()

func is_warrant_desk_open():
	var day = get_day() % 7
	var hour = get_hour()
	return day < 5 and hour >= 8 and hour < 20

func buy_search_warrant():
	if _player_location != PlayerLocation.WARRANT_DESK:
		await pass_one_hour()
		set_player_location(PlayerLocation.WARRANT_DESK)
	var ok = await Globals.dialog_overlay.buy_search_warrant()
	if ok:
		player.money -= warrant_price
		player.has_search_warrant = true
		save_game()

func pay_debt(debt_index: int):
	if _player_location != PlayerLocation.OFFICE:
		await pass_one_hour()
		set_player_location(PlayerLocation.OFFICE)
	await pass_one_hour()
	await player.pay_debt(debt_index)

func use_drugs(doses: int):
	if _player_location != PlayerLocation.OFFICE:
		await pass_one_hour()
		set_player_location(PlayerLocation.OFFICE)
	await pass_one_hour()
	await player.use_drugs(doses)

func get_player_drug_price() -> int:
	var price: int = 25
	if "dealer_discount" in player.job_bonus_malus:
		price = roundi(price * player.job_bonus_malus.dealer_discount)
	return price

func can_visit_dealer() -> bool:
	var price = get_player_drug_price()
	var travel_time = 0 if _player_location == PlayerLocation.ROWENA else 1
	var eta = get_hour() + travel_time
	return (eta < 8 or eta >= 20) \
		and player.money >= price and player.get_debt_count() == 0

func visit_dealer():
	if _player_location != PlayerLocation.ROWENA:
		await pass_one_hour()
		set_player_location(PlayerLocation.ROWENA)
	var price = get_player_drug_price()
	var doses = await Globals.dialog_overlay.visit_dealer(
		_dealer_drug_stock, player.money, price)
	if doses > 0:
		_dealer_drug_stock -= doses
		player.money -= doses * price
		player.drugs += doses

func get_player_doctor_fee() -> int:
	var price: int = 50
	if "doctor_discount" in player.job_bonus_malus:
		price = roundi(price * player.job_bonus_malus.doctor_discount)
	return price

func can_visit_doctor() -> bool:
	var day = get_day()
	var travel_time = 0 if _player_location == PlayerLocation.DOCTOR else 1
	var eta = get_hour() + travel_time
	var fee = get_player_doctor_fee()
	if day % 7 >= 5 or eta < 8 or eta >= 20 \
		or player.money < fee or player.get_debt_count() > 0:
		return false
	return _last_doctor_day < 0 or day - _last_doctor_day >= 4

func visit_doctor():
	if _player_location != PlayerLocation.DOCTOR:
		await pass_one_hour()
		set_player_location(PlayerLocation.DOCTOR)

	var fee = get_player_doctor_fee()

	if await Globals.dialog_overlay.visit_doctor(fee):
		player.money -= fee
		player.health += 3
		player.improve_emotion(2)
		player.improve_addiction(1)
		_last_doctor_day = get_day()
		save_game()

func attempt_investigation(location: LocationCard):

	# go to the location first

	if (_player_location != PlayerLocation.OTHER
		or _player_location_card != location):
		await pass_one_hour()
		set_player_location(PlayerLocation.OTHER, location)

	# check whether there is anybody there, whether the player has a warrant he
	# can use or if he wants to break in, etc.

	var npcs = location.get_npcs_present()
	var break_in_needed = false

	# if no NPCs are present, the player can either try to break in or leave

	if npcs.is_empty():
		if not await Globals.dialog_overlay.confirm_break_in():
			return
		break_in_needed = true

	# if NPCs are present and the player has a search warrant, ask if he wants
	# to use it

	elif GameState.player.has_search_warrant:
		if not await Globals.dialog_overlay.use_search_warrant():
			return
		GameState.player.has_search_warrant = false

	# if NPCs are present and the player does NOT have a search warrant, there
	# is nothing he can do

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
		_current_interaction_location = location
		save_game()
		var cards = await Globals.dialog_overlay.attempt_break_in()
		if not await _play_break_in(cards):
			end_interaction()
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
		start_investigation(_current_interaction_location)
	else:
		end_interaction()

##
## Called if the game was interrupted during a run-away attempt, to resume where
## we left off.
##
func resume_run_away():
	var cards = await Globals.dialog_overlay.attempt_run_away()
	if await _play_run_away(cards):
		end_interaction()
	else:
		start_combat(_current_interaction_npc, _current_interaction_location)

#
# Game logic for a break-in. Given the current location card, and the optional
# cards played (break-in and/or abstract cards), rolls the dice to determine
# whether the break-in is successful or not. Returns true if the break-in is
# successful.
#
func _play_break_in(cards_played: Array[Card]) -> bool:
	print("\n*** break-in: %s ***" % _current_interaction_location.get_display_name())

	# retrieve bonus/malus points from the cards played: PHY, MEN and HEA
	# changes are temporary; Emo and Add changes are permanent

	var attrs = InteractionAttributes.new()
	attrs.play_card(_current_interaction_location, false)
	for card in cards_played:
		attrs.play_card(card, card in player.get_fallback_cards())

	# roll the die

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

	await Globals.dialog_overlay.show_break_in_message(success)

	if actual_roll == 10:
		await Globals.dialog_overlay.show_player_improvement(-1)
	elif actual_roll == 1:
		await Globals.dialog_overlay.show_player_improvement(1, critical_attr)

	return success

#
# Game logic for a run-away attempt before a combat. Given the current location
# and NPC, and the optional cards played (run-away and/or abstract cards), rolls
# the dice to determine whether the attempt is successful or not. Returns true
# if it is.
#
func _play_run_away(cards_played: Array[Card]) -> bool:
	print("\n*** run away: %s ***" % _current_interaction_location.get_display_name())

	# retrieve bonus/malus points from the cards played: PHY, MEN and HEA
	# changes are temporary; Emo and Add changes are permanent

	var attrs = InteractionAttributes.new()
	attrs.play_card(_current_interaction_location, false)
	for card in cards_played:
		attrs.play_card(card, card in player.get_fallback_cards())

	# roll the die

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
				player.max_health += value
				return &"maxHEA"

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

	return success

#
# Game logic for an investigation (possibly following a break-in).
#
func _play_investigation(cards_played: Array[Card]):
	print("\n*** investigation: %s ***" % _current_interaction_location.get_display_name())

	# retrieve bonus/malus points from the cards played: PHY, MEN and HEA
	# changes are temporary; Emo and Add changes are permanent

	var attrs = InteractionAttributes.new()
	attrs.play_card(_current_interaction_location, false)
	for card in cards_played:
		attrs.play_card(card, card in GameState.player.get_fallback_cards())

	# roll the die

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
				who.max_health += value
				return &"maxHEA"

	var success = false
	var critical_attr: StringName

	if actual_roll == 10:
		player.health -= 1
		critical_attr = tweak_attr.call(player, -1)
		print("critical failure: update HEA, %s" % critical_attr)
	elif actual_roll == 1:
		critical_attr = tweak_attr.call(player, 1)
		player.money += randi_range(50, 100)
		print("critical success: update %s, money" % critical_attr)
		success = true
	elif net_roll > max_roll:
		player.emotion -= 1
		print("failure: update Emo")
	else:
		print("success: margin = %s" % [max_roll - net_roll])
		success = true

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
	if duration > 0:
		await _increment_time(duration)

##
## Starts an investigation interaction: picks the fallback cards for the
## investigation, saves the state of the cards in the Main scene (before we
## switch to the Interaction scene), and emits an interaction_started() signal
## telling The Game to switch scenes.
##
func start_investigation(location: LocationCard):
	player.pick_investigation_cards()
	_current_interaction = InteractionType.INVESTIGATION
	_current_interaction_location = location
	_push_card_state()
	save_game()
	interaction_started.emit()

func attempt_dialogue(npc: NpcCard, location: LocationCard):

	# go to the location first

	if (_player_location != PlayerLocation.OTHER
		or _player_location_card != location):
		await pass_one_hour()
		set_player_location(PlayerLocation.OTHER, location)

	# check whether the NPC is there

	if npc.locate() != location:
		await Globals.dialog_overlay.show_npc_away(npc)
		return

	var is_first_visit = not npc.has_been_seen()
	npc.visit()

	# the NPC may try to run away

	if not is_first_visit and await _does_npc_run(npc):
		return

	# if the NPC attacks the player, start a combat, not a dialogue, and give
	# the player the chance to try to run away first

	if not is_first_visit and _does_npc_attack(npc):
		await Globals.dialog_overlay.show_attack_message(npc)
		if await Globals.dialog_overlay.confirm_run_away():
			player.pick_run_away_cards()
			_current_interaction = InteractionType.RUN_AWAY
			_current_interaction_location = location
			_current_interaction_npc = npc
			save_game()
			var cards = await Globals.dialog_overlay.attempt_run_away()
			if await _play_run_away(cards):
				end_interaction()
				return
		start_combat(npc, location)
	else:
		start_dialogue(npc, location)

##
## Starts a dialogue interaction: picks the fallback cards for the dialogue,
## saves the state of the cards in the Main scene (before we switch to the
## Interaction scene), and emits an interaction_started() signal telling The
## Game to switch scenes.
##
## There is one case where we do NOT want the state of the cards to be saved
## first: when going directly from a combat to a dialogue, because we are
## already in the Interaction scene. In that case, save_card_state should be
## false.
##
func start_dialogue(
		npc: NpcCard, location: LocationCard, save_card_state: bool = true):
	player.pick_dialogue_cards()
	_current_interaction = InteractionType.DIALOGUE
	_current_interaction_location = location
	_current_interaction_npc = npc
	if save_card_state:
		_push_card_state()
	save_game()
	interaction_started.emit()

func _play_dialogue(cards_played: Array[Card]):
	var npc: NpcCard = _current_interaction_npc
	print("\n*** dialogue: %s ***" % npc.get_display_name())

	# retrieve bonus/malus points from the cards played: PHY, MEN and HEA
	# changes are temporary; Emo and Add changes are permanent

	var attrs = InteractionAttributes.new()
	attrs.play_card(_current_interaction_location, false)
	for card in cards_played:
		attrs.play_card(card, card in GameState.player.get_fallback_cards())

	var bonus_malus = attrs.get_bonus_malus()
	var rep = npc.player_reputation
	if rep != 0:
		bonus_malus -= rep
		print("Rep bonus/malus: %s" % -rep)
	if player.next_dialogue_bonus_malus != 0:
		bonus_malus += player.next_dialogue_bonus_malus
		print("dialogue bonus/malus: %s" % player.next_dialogue_bonus_malus)
		player.next_dialogue_bonus_malus = 0

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
				who.max_health += value
				return &"maxHEA"

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
			player.improve_emotion(-1)
			print("critical success: update Emo, %s" % critical_attr)
		success = true

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

	if actual_roll > 1:
		if npc_actual_roll == 1:
			print("failure due to NPC's critical success")
		else:
			var margin = max_roll - net_roll
			var npc_margin = npc_max_roll - npc_net_roll
			print("player success margin: %s" % margin)
			print("NPC success margin: %s" % npc_margin)
			print("net success margin: %s" % (margin - npc_margin))
			success = (margin >= npc_margin)

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

	if rep_delta != 0:
		var old_rep = npc.player_reputation
		npc.player_reputation += rep_delta
		var actual_delta = npc.player_reputation - old_rep
		if absi(actual_delta) > 1:
			await Globals.dialog_overlay.show_rep_message(actual_delta > 0)

	if actual_roll == 10:
		await Globals.dialog_overlay.show_player_improvement(-1)
	elif actual_roll == 1:
		await Globals.dialog_overlay.show_player_improvement(1, critical_attr)

	await _increment_time(2)

##
## Starts a combat interaction: picks the fallback cards for the combat, saves
## the state of the cards in the Main scene (before we switch to the Interaction
## scene), and emits an interaction_started() signal telling The Game to switch
## scenes.
##
func start_combat(npc: NpcCard, location: LocationCard):
	player.pick_combat_cards()
	_current_interaction = InteractionType.COMBAT
	_current_interaction_location = location
	_current_interaction_npc = npc
	_push_card_state()
	save_game()
	interaction_started.emit()

#
# Rolls the dice for a combat. Returns true if a dialogue will follow the
# combat, that is, if the player played a Do Not Kill card and was "successful",
# meaning either he rolled a 1 (critical success) or his roll was good enough to
# do some damage.
#
func _play_combat(cards_played: Array[Card]) -> bool:
	var loc: LocationCard = _current_interaction_location
	var npc: NpcCard = _current_interaction_npc
	print("\n*** combat: %s with %s ***"
		  % [loc.get_display_name(), npc.get_display_name()])

	# retrieve bonus/malus points from the cards played: PHY, MEN and HEA
	# changes are temporary; Emo and Add changes are permanent

	var attrs = InteractionAttributes.new()
	attrs.play_card(_current_interaction_location, false)
	for card in cards_played:
		attrs.play_card(card, card in player.get_fallback_cards())

	# roll the die for the player

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
				who.max_health += value
				return &"maxHEA"

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
	# player receives a bonus for the ensuing dialogue

	var do_not_kill = false

	for card in cards_played:
		if card is CombatCard:
			var combat_bonus_malus = \
				_combat_data[card.database_id].get("bonus_malus", {})
			if combat_bonus_malus.get("other") == "opponent_survives":
				do_not_kill = true
				break

	if do_not_kill and npc_damage > 0:
		npc_damage = mini(npc_damage, npc.health - 1)
		player.next_dialogue_bonus_malus = -1

	print("player inflicts %d damage point(s) on NPC" % npc_damage)
	print("NPC inflicts %d damage point(s) on player" % damage)

	player.health -= damage
	npc.health -= npc_damage
	npc.wanted += 1
	npc.player_reputation -= 2

	# TODO: if NPC dies, player searches him and has 25% chance of finding 100
	# units of money (+/- 10%) and 25% chance of adding +1 Wan

	if actual_roll == 10:
		await Globals.dialog_overlay.show_player_improvement(-1)
	elif actual_roll == 1:
		await Globals.dialog_overlay.show_player_improvement(1, critical_attr)

	await _increment_time(2)

	return do_not_kill and (actual_roll == 1 or max_roll > net_roll)

##
## Called when the player has clicked on the OK button in the Interaction scene
## to proceed with (that is, roll the dice for) the current interaction. All the
## game logic is performed, the current interaction is reset, and the state of
## the cards is restored before we switch from the Interaction scene back to the
## Main scene.
##
## Returns true in one case only: if the interaction was a combat, and if the
## player played a Do Not Kill card (and was not killed himself), so that a
## dialogue with the NPC may ensue. In that case, since we will be staying in
## the Interaction scene rather than switching to the Main scene, the state of
## the cards for Main is NOT restored yet.
##
func end_interaction(cards_played: Array[Card] = []):
	var dialogue_ensues = false

	match _current_interaction:
		InteractionType.INVESTIGATION:
			await _play_investigation(cards_played)
			_pop_card_state()
		InteractionType.DIALOGUE:
			await _play_dialogue(cards_played)
			_current_interaction_npc.test_health()
			_pop_card_state()
		InteractionType.COMBAT:
			dialogue_ensues = await _play_combat(cards_played)
			_current_interaction_npc.test_health()
			if not dialogue_ensues:
				_pop_card_state()

	player.clear_fallback_cards()
	_current_interaction = InteractionType.NONE
	_current_interaction_location = null
	_current_interaction_npc = null
	_current_interaction_bonus_malus = 0

	if await player.test_health():
		save_game()
		return dialogue_ensues
	else:
		if dialogue_ensues:
			_pop_card_state()
		died.emit()
		return false

func get_current_interaction() -> InteractionType:
	return _current_interaction

func get_current_interaction_location() -> LocationCard:
	return _current_interaction_location

func get_current_interaction_npc() -> NpcCard:
	return _current_interaction_npc

func get_current_case() -> Case:
	if _current_case_index >= 0:
		return cases[_current_case_index]
	else:
		return null

func set_current_case(index: int):
	if _current_case_index != index:
		if _current_case_index >= 0 and _current_case_index < cases.size():
			cases[_current_case_index].pause()
		_current_case_index = index
		if _current_case_index >= 0 and _current_case_index < cases.size():
			cases[_current_case_index].start()
		case_changed.emit()
		save_game()

##
## Specifies where the player is located. If location is PlayerLocation.OTHER,
## then a LocationCard must be given.
##
func set_player_location(location: PlayerLocation, card: LocationCard = null):
	if _player_location != location or _player_location_card != card:
		_player_location = location
		_player_location_card = card
		location_changed.emit()

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
func _does_npc_run(npc: NpcCard) -> bool:

	# in most cases he does not try

	if randi() % (2 * npc.mental) > 0:
		return false

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
				npc.max_health += value

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

	if success:
		npc.wanted += 1
	else:
		npc.next_dialogue_malus = 1

	npc.test_health()
	save_game()

	await Globals.dialog_overlay.show_npc_run(success)

	return success

#
# The chances of the NPC attacking the player before a dialogue depend on
# whether the player has met him before, his reputation, the number of
# incriminating links the player has established, and the difficulty of the
# case.
#
func _does_npc_attack(npc: NpcCard) -> bool:
	var percent: int = 0

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

	return randi_range(1, 100) > percent * case.get_difficulty()

#
# Saves the visual state of all object, location and NPC cards that are visible
# to the player. This is done before switching from the main scene to the
# interaction scene so that, however the cards move around during the
# interaction, they can be put back where they were afterwards.
#
func _push_card_state():
	for card in get_current_case().get_revealed_cards():
		if card.get_card_type() in [
			Card.CardType.OBJECT, Card.CardType.LOCATION, Card.CardType.NPC
		]:
			card.push_state()

#
# Restores the visual state of all object, location and NPC cards after a
# previous call to _push_card_state(). This is done before switching back from
# the interaction scene to the main scene.
#
func _pop_card_state():
	for card in get_current_case().get_revealed_cards():
		if card.get_card_type() in [
			Card.CardType.OBJECT, Card.CardType.LOCATION, Card.CardType.NPC
		]:
			card.pop_state()

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
	_has_visited_hub = other._has_visited_hub
	_last_doctor_day = other._last_doctor_day
	_dealer_drug_stock = other._dealer_drug_stock
	_last_crimes = other._last_crimes
	_current_case_index = other._current_case_index
	_player_location = other._player_location
	_player_location_card = other._player_location_card
	_current_interaction = other._current_interaction
	_current_interaction_location = other._current_interaction_location
	_current_interaction_npc = other._current_interaction_npc
	_current_interaction_bonus_malus = other._current_interaction_bonus_malus

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
	if _current_interaction_location:
		refs.append(_current_interaction_location)
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
		"has_visited_hub": _has_visited_hub,
		"last_doctor_day": _last_doctor_day,
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
		if _current_interaction_location:
			dict["interaction_location"] = _current_interaction_location.get_unique_id()
		if _current_interaction_npc:
			dict["interaction_npc"] = _current_interaction_npc.get_unique_id()
		if _current_interaction_bonus_malus != 0:
			dict["interaction_bonus_malus"] = _current_interaction_bonus_malus

	return dict

#
# For save/load.
#
func restore(dict, catalog):
	_hour = dict.hour
	_has_visited_hub = dict.get("has_visited_hub", false)
	_last_doctor_day = dict.get("last_doctor_day", -1)
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
		if "interaction_location" in dict:
			_current_interaction_location = catalog[dict.interaction_location]
		if "interaction_npc" in dict:
			_current_interaction_npc = catalog[dict.interaction_npc]
		_current_interaction_bonus_malus = dict.get("interaction_bonus_malus", 0)

#
# For save/load.
#
func allocate() -> Object:
	return load("res://SCRIPTS/Game_State.gd").new()
