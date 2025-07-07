extends Node

var player: Player = Player.new()
var cases: Array[Case]

## Signal emitted when the time has changed: see get_day() and get_hour().
@warning_ignore("unused_signal")
signal time_changed

## Signal emitted when the current case has changed: see get_current_case().
signal case_changed

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

# where game state is saved/reloaded
const _save_path = "user://game.sav"

# play starts at 8am Monday
const _start_time = 8

# hours passed since the first Monday at midnight
var _hour: int

# the day the player last visited the investigation center
var _last_hub_visit_day: int

# the crimes of the last several cases generated, to avoid repetition
var _last_crimes: Array[String]

# which case is current
var _current_case_index: int

func _ready():
	#load_game()
	pass

func start_game():
	_hour = _start_time
	_last_hub_visit_day = -1
	_last_crimes.clear()
	_current_case_index = -1

	cases.clear()
	for i in 5:
		cases.append(Case.generate())

	player.start_game()

##
## Returns the number of full days that have passed since play began. Play
## always begins on Monday, so the number of days % 7 gives you the day of the
## week (0 for Monday).
##
func get_day() -> int:
	@warning_ignore("integer_division")
	return _hour / 24

##
## Returns the current time (hour), in the range 0-23.
##
func get_hour() -> int:
	return _hour % 24

func _get_weeks_passed() -> int:
	@warning_ignore("integer_division")
	return (_hour - _start_time) / (24 * 7)

func _increment_time(hours: int):
	var bill_count_before = _get_weeks_passed()
	_hour += hours
	var bill_count_after = _get_weeks_passed()
	time_changed.emit()

	# send a new bill at the start of each week
	for i in bill_count_after - bill_count_before:
		_send_new_bill()

	#save_game()

func pass_one_hour():
	player.pass_one_hour()
	_increment_time(1)

func sleep(hours: int):
	player.sleep(hours)
	_increment_time(hours)

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

func save_game():
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		var dict = {
			"_hour": _hour
		}
		dict.set("player", player.save())
		var json = JSON.stringify(dict, "\t")
		file.store_line(json)

func load_game():
	var json = FileAccess.get_file_as_string(_save_path)
	if json:
		var data = JSON.parse_string(json)
		if data and data is Dictionary:
			_hour = data["_hour"]
			player.load(data["player"])

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
## Returns false if the player has already visited the Investigation Center
## today.
##
func can_visit_investigation_center() -> bool:
	return _last_hub_visit_day < 0 or _last_hub_visit_day < get_day()

func visit_investigation_center():
	if can_visit_investigation_center():
		_last_hub_visit_day = get_day()
		await pass_one_hour()
		await Globals.dialog_overlay.open_investigation_center()

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
