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
	INVESTIGATION
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

func _increment_time(hours: int):
	var day_before = get_working_day()
	_hour += hours
	var day_after = get_working_day()
	time_changed.emit()

	for day in range(day_before + 1, day_after + 1):
		_new_day(day)

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
	player.drugs_taken_today = 0

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

func pass_one_hour():
	player.pass_one_hour()
	_increment_time(1)

##
## Returns false if the player has already slept today.
##
func can_sleep() -> bool:
	return not _has_slept

func sleep(hours: int):
	if _player_location != PlayerLocation.OFFICE:
		await pass_one_hour()
		set_player_location(PlayerLocation.OFFICE)
	await player.sleep(hours)
	_increment_time(hours)
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

func start_investigation(location: LocationCard):
	if (_player_location != PlayerLocation.OTHER
		or _player_location_card != location):
		await pass_one_hour()
		set_player_location(PlayerLocation.OTHER, location)

	var npcs = location.get_npcs_present()

	# if no NPCs are present, the player can either try to break in or leave

	if npcs.is_empty():
		var ok = await Globals.dialog_overlay.confirm_break_in()
		if not ok:
			return

	# if NPCs are present and the player has a search warrant, ask if he wants
	# to use it

	elif GameState.player.has_search_warrant:
		var ok = await Globals.dialog_overlay.use_search_warrant()
		if not ok:
			return

	# if NPCs are present and the player does NOT have a search warrant, there
	# is nothing he can do

	else:
		await Globals.dialog_overlay.no_search_warrant()
		return

	player.pick_investigation_cards()
	_current_interaction = InteractionType.INVESTIGATION
	_current_interaction_card = location
	save_game()
	interaction_started.emit()

func end_interaction():
	player.clear_fallback_cards()
	_current_interaction = InteractionType.NONE
	_current_interaction_card = null

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

#
# For save/load.
#
func allocate() -> Object:
	return load("res://SCRIPTS/Game_State.gd").new()
