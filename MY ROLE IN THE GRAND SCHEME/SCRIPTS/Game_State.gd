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

var player: Player = Player.new()
var cases: Array[Case]

## Signal emitted when the time has changed: see get_day() and get_hour().
@warning_ignore("unused_signal")
signal time_changed

## Signal emitted when the current case has changed: see get_current_case().
signal case_changed

## Signal emitted when the player changes location.
signal player_location_changed

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

# the crimes of the last several cases generated, to avoid repetition
var _last_crimes: Array[String]

# which case is current
var _current_case_index: int

var _player_location: PlayerLocation = PlayerLocation.OFFICE
var _player_location_card: LocationCard

func _ready():
	load_game()

func start_game():
	_hour = _start_time
	_has_visited_hub = false
	_has_slept = false
	_last_crimes.clear()
	_current_case_index = -1
	_player_location = PlayerLocation.OFFICE
	_player_location_card = null

	cases.clear()
	for i in 5:
		cases.append(Case.generate())

	player.start_game()

func end_game():
	cases.clear()
	player.reset()
	DirAccess.remove_absolute(_save_path)

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
	
	# send the player a new bill every Monday

	if day % 7 == 0:
		_send_new_bill()

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
	if can_sleep():
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
	if can_visit_investigation_center():
		await pass_one_hour()
		set_player_location(PlayerLocation.INVESTIGATION_CENTER)
		_has_visited_hub = true
		await Globals.dialog_overlay.open_investigation_center()

func visit_office():
	await pass_one_hour()
	set_player_location(PlayerLocation.OFFICE)
	await Globals.dialog_overlay.open_office()

func is_warrant_desk_open():
	var day = get_day() % 7
	var hour = get_hour()
	return day <= 5 and hour >= 8 and hour < 20

func buy_search_warrant():
	await pass_one_hour()
	set_player_location(PlayerLocation.WARRANT_DESK)
	var ok = await Globals.dialog_overlay.buy_search_warrant()
	if ok:
		player.money -= 25
		player.has_search_warrant = true
		save_game()

func get_current_case() -> Case:
	if _current_case_index >= 0:
		return cases[_current_case_index]
	else:
		return null

func set_current_case(index: int):
	if _current_case_index != index:
		if _current_case_index >= 0:
			cases[_current_case_index].pause()
		_current_case_index = index
		if _current_case_index >= 0:
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
		player_location_changed.emit()

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

func assign(other):
	player.assign(other.player)
	_hour = other._hour
	_has_visited_hub = other._has_visited_hub
	_has_slept = other._has_slept
	_last_crimes = other._last_crimes
	_current_case_index = other._current_case_index
	_player_location = other._player_location
	_player_location_card = other._player_location_card
	cases = other.cases

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
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	_hour = dict.hour
	_has_visited_hub = dict.get("has_visited_hub", false)
	_has_slept = dict.get("has_slept", false)
	_last_crimes.assign(dict.last_crimes)
	_current_case_index = dict.current_case_index
	player = catalog[dict.player]
	for case_ref in dict.get("cases", []):
		cases.append(catalog[case_ref])
	if "player_location" in dict:
		_player_location = dict.player_location
		print("restore: player_location: ", _player_location)
		if "player_location_card" in dict:
			_player_location_card = catalog[dict.player_location_card]

#
# For save/load.
#
func allocate() -> Object:
	return load("res://SCRIPTS/Game_State.gd").new()
