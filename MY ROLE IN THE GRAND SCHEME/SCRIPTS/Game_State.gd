extends Node

var player: Player = Player.new()
var cases: Array[Case]

@warning_ignore("unused_signal")
signal time_changed

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

# hours passed since the first Monday at midnight
var _hour: int

# play starts at 8am Monday
const _start_time = 8

# where game state is saved/reloaded
const _save_path = "user://game.sav"

# the crimes of the last several cases generated, to avoid repetition
var _last_crimes: Array[String]

func _ready():
	load_game()

func start_game():
	_hour = _start_time
	player.start_game()
	for i in 5:
		cases.append(Case.generate())

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

	save_game()

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
