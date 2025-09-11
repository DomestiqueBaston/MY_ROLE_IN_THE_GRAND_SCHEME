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
	BREAK_IN
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

## Price for a dose of drugs.
const drug_price: int = 25

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

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

# where game state is saved/reloaded
const _save_path = "user://game.sav"

# play starts at 8am Monday
const _start_time = 8

# hours passed since the first Monday at midnight
var _hour: int

# has the player visited the investigation center today?
var _has_visited_hub: bool

# has the player slept today?
var _has_slept: bool

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
var _current_interaction_card: Card
var _current_interaction_bonus_malus: int

func _ready():
	load_game()

func start_game():
	_hour = _start_time
	_has_visited_hub = false
	_has_slept = false
	_last_doctor_day = -1
	_dealer_drug_stock = randi_range(5, 10)
	_last_crimes.clear()
	_current_case_index = -1
	_player_location = PlayerLocation.OFFICE
	_player_location_card = null
	_current_interaction = InteractionType.NONE
	_current_interaction_card = null
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
	_has_slept = false
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
## Returns false if the player has already slept today.
##
func can_sleep() -> bool:
	return not _has_slept

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
	_has_slept = true

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

func can_visit_dealer() -> bool:
	var hour = get_hour()
	return (hour < 8 or hour >= 20) \
		and player.money >= drug_price and player.get_debt_count() == 0

func visit_dealer():
	if _player_location != PlayerLocation.ROWENA:
		await pass_one_hour()
		set_player_location(PlayerLocation.ROWENA)
	var doses = await Globals.dialog_overlay.visit_dealer(
		_dealer_drug_stock, player.money)
	if doses > 0:
		_dealer_drug_stock -= doses
		player.money -= doses * drug_price
		player.drugs += doses

func can_visit_doctor() -> bool:
	var day = get_day()
	var hour = get_hour()
	if day % 7 >= 5 or hour < 8 or hour >= 20 \
		or player.money < 50 or player.get_debt_count() > 0:
		return false
	return _last_doctor_day < 0 or day - _last_doctor_day >= 7

func visit_doctor():
	if _player_location != PlayerLocation.DOCTOR:
		await pass_one_hour()
		set_player_location(PlayerLocation.DOCTOR)
	var ok = await Globals.dialog_overlay.visit_doctor()
	if ok:
		player.money -= 50
		player.health += 2
		player.improve_emotion(1)
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

	# if NPCs are present and the player does NOT have a search warrant, there
	# is nothing he can do

	else:
		await Globals.dialog_overlay.no_search_warrant()
		return

	# if nobody is there and the player wants to break in, set up the pseudo-
	# interaction (pseudo because it takes place not in the Interaction scene
	# but in an overlay of the Main scene) and try to break in

	if break_in_needed:
		player.pick_break_in_cards()
		_current_interaction = InteractionType.BREAK_IN
		_current_interaction_card = location
		save_game()
		var cards = await Globals.dialog_overlay.attempt_break_in(location)
		if not _play_break_in(cards):
			end_interaction()
			return

	# finally, start the investigation

	await start_investigation(location)

##
## Called if the game was interrupted during a break-in, to resume where we
## left off.
##
func resume_break_in():
	var cards = await Globals.dialog_overlay.attempt_break_in(
		_current_interaction_card)
	if _play_break_in(cards):
		start_investigation(_current_interaction_card)
	else:
		end_interaction()

#
# Game logic for a break-in. Given the current location card, and the optional
# cards played (break-in and/or abstract cards), rolls the dice to determine
# whether the break-in is successful or not. Returns true if the break-in is
# successful.
#
func _play_break_in(cards_played: Array[Card]) -> bool:

	# retrieve bonus/malus points from the cards played: PHY, MEN and HEA
	# changes are temporary; Emo and Add changes are permanent

	var attrs = InteractionAttributes.new()
	attrs.play_card(_current_interaction_card)
	for card in cards_played:
		attrs.play_card(card)
	attrs.apply_changes_to_player()

	# roll the dice

	var bonus_malus = player.get_bonus_malus()
	print("player bonus/malus: %s" % bonus_malus)
	if cards_played.is_empty():
		bonus_malus += 1
		print("no cards played => malus 1")
	var min_roll = roundi((attrs.PHY + attrs.MEN + attrs.HEA) / 3.0) + bonus_malus
	print("min roll: %s" % min_roll)
	var roll = randi_range(1, 10)
	print("actual roll: %s" % roll)

	if roll == 10:
		print("critical failure: update HEA, Emo, Wan")
		player.health -= 1
		player.emotion = Player.exacerbate(player.emotion)
		player.wanted += 1
	elif roll == 1:
		print("critical success: update Emo")
		player.emotion = Player.calm(player.emotion)
		_current_interaction_bonus_malus = -1
	elif roll > min_roll:
		print("failure: update Emo, Wan")
		player.emotion = Player.exacerbate(player.emotion)
		player.wanted += 1
	else:
		print("success: margin = %s" % [min_roll - roll])

	return roll == 1 or roll <= min_roll

#
# Game logic for an investigation (possibly following a break-in).
#
func _play_investigation(cards_played: Array[Card]):

	# retrieve bonus/malus points from the cards played: PHY, MEN and HEA
	# changes are temporary; Emo and Add changes are permanent

	var attrs = InteractionAttributes.new()
	attrs.play_card(_current_interaction_card)
	for card in cards_played:
		attrs.play_card(card)
	attrs.apply_changes_to_player()

	# roll the dice

	var bonus_malus = player.get_bonus_malus()
	print("player bonus/malus: %s" % bonus_malus)
	var min_roll = roundi((attrs.PHY + attrs.MEN + attrs.HEA) / 3.0) \
		+ bonus_malus + _current_interaction_bonus_malus
	print("min roll: %s" % min_roll)
	var roll = randi_range(1, 10)
	print("actual roll: %s" % roll)

	if roll == 10:
		print("critical failure: update HEA, Emo")
		player.health -= 1
		player.emotion -= 1
	elif roll == 1:
		print("critical success: update money")
		player.money += randi_range(50, 100)
	elif roll > min_roll:
		print("failure: update Emo")
		player.emotion -= 1
	else:
		print("success: margin = %s" % [min_roll - roll])

func start_investigation(location: LocationCard):
	player.pick_investigation_cards()
	_current_interaction = InteractionType.INVESTIGATION
	_current_interaction_card = location
	save_game()
	interaction_started.emit()

func end_interaction(cards_played: Array[Card] = []):
	if _current_interaction == InteractionType.INVESTIGATION:
		_play_investigation(cards_played)

	player.clear_fallback_cards()
	_current_interaction = InteractionType.NONE
	_current_interaction_card = null
	_current_interaction_bonus_malus = 0
	if await player.test_health():
		save_game()
	else:
		died.emit()

func get_current_interaction() -> InteractionType:
	return _current_interaction

func get_current_interaction_card() -> Card:
	return _current_interaction_card

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
	_has_slept = other._has_slept
	_last_doctor_day = other._last_doctor_day
	_dealer_drug_stock = other._dealer_drug_stock
	_last_crimes = other._last_crimes
	_current_case_index = other._current_case_index
	_player_location = other._player_location
	_player_location_card = other._player_location_card
	_current_interaction = other._current_interaction
	_current_interaction_card = other._current_interaction_card
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
	if _current_interaction_card:
		refs.append(_current_interaction_card)
	return refs

#
# For save/load.
#
func get_json_dict():
	var dict = {
		"player": player.get_unique_id(),
		"hour": _hour,
		"has_visited_hub": _has_visited_hub,
		"has_slept": _has_slept,
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
		if _current_interaction_card:
			dict["interaction_card"] = _current_interaction_card.get_unique_id()
		if _current_interaction_bonus_malus != 0:
			dict["interaction_bonus_malus"] = _current_interaction_bonus_malus

	return dict

#
# For save/load.
#
func restore(dict, catalog):
	_hour = dict.hour
	_has_visited_hub = dict.get("has_visited_hub", false)
	_has_slept = dict.get("has_slept", false)
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
		if "interaction_card" in dict:
			_current_interaction_card = catalog[dict.interaction_card]
		_current_interaction_bonus_malus = dict.get("interaction_bonus_malus", 0)

#
# For save/load.
#
func allocate() -> Object:
	return load("res://SCRIPTS/Game_State.gd").new()
