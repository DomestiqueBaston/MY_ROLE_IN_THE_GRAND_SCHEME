extends Node

var _day: int
var _hour: int

@onready var player: Player = $Player

@warning_ignore("unused_signal")
signal time_changed

func start_game():
	_day = 0
	_hour = 0
	player.start_game()

func get_day() -> int:
	return _day

func get_hour() -> int:
	return _hour

func _increment_time(hours: int):
	_hour += hours
	if _hour >= 24:
		@warning_ignore("integer_division")
		_day += _hour / 24
		_hour = _hour % 24
	time_changed.emit()

func pass_one_hour():
	player.pass_one_hour()
	_increment_time(1)

func sleep(hours: int):
	if hours >= 4:
		player.sleep(hours)
		_increment_time(hours)
