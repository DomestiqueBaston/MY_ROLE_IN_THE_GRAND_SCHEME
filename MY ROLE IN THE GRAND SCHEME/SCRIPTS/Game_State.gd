extends Node

# hours passed since the first Monday at midnight
var _hour: int

# play starts at 8am Monday
const _start_time = 8

@onready var player: Player = $Player

@warning_ignore("unused_signal")
signal time_changed

func start_game():
	_hour = _start_time
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

func pass_one_hour():
	player.pass_one_hour()
	_increment_time(1)
	_send_new_bill()

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
