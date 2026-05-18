class_name Paranoia extends RefCounted

## Class used to track the player's experience and to determine when an attack
## of paranoia hits. Modify the following variables as play progresses, call
## update() to determine if the conditions for a paranoia attack have been met,
## and check() to test whether the conditions have been met previously without
## actually performing an update.

var drug_crisis_count: int = 0
var abandoned_case_count: int = 0
var failed_case_count: int = 0
var short_night_count: int = 0
var bad_health_period: int = 0
var minion_attack_count: int = 0
var sms_count: int = 0
var unpaid_bill_count: int = 0

var _paranoia_flag: bool = false

func reset():
	drug_crisis_count = 0
	abandoned_case_count = 0
	failed_case_count = 0
	short_night_count = 0
	bad_health_period = 0
	minion_attack_count = 0
	sms_count = 0
	unpaid_bill_count = 0
	_paranoia_flag = false

##
## Updates the paranoid flag, if it has not already been set, depending on how
## many drug crises the player has survived, how many SMS messages he has
## received, etc. The volume of the "paranoia voices" is also set accordingly.
##
func update() -> bool:
	if not _paranoia_flag:
		var level: float = max(
			drug_crisis_count / 5.0,
			abandoned_case_count / 5.0,
			failed_case_count / 5.0,
			short_night_count / 10.0,
			bad_health_period / 5.0,
			minion_attack_count / 15.0,
			sms_count / 15.0,
			unpaid_bill_count / 10.0
		)
		if level > 0:
			print("*** paranoia level: %d%%" % roundi(level * 100))
		Globals.set_paranoia_voice_level(level)
		if level > 0.99:
			_paranoia_flag = true
	return _paranoia_flag

##
## Returns true if the paranoid flag has been set.
##
func check() -> bool:
	return _paranoia_flag

#
# For save/load. Note that this is called directly from Player.get_json_dict(),
# so there is no need to implement get_custom_class(), get_unique_id() or an
# allocator.
#
func get_json_dict():
	var dict = {
		"drug_crisis_count": drug_crisis_count,
		"abandoned_case_count": abandoned_case_count,
		"failed_case_count": failed_case_count,
		"short_night_count": short_night_count,
		"bad_health_period": bad_health_period,
		"minion_attack_count": minion_attack_count,
		"sms_count": sms_count,
		"unpaid_bill_count": unpaid_bill_count
	}
	return dict

#
# For save/load. Note that this is called directly from Player.restore(), so
# there is no need to implement get_custom_class(), get_unique_id() or an
# allocator.
#
func restore(dict, _catalog):
	drug_crisis_count = dict.get("drug_crisis_count", 0)
	abandoned_case_count = dict.get("abandoned_case_count", 0)
	failed_case_count = dict.get("failed_case_count", 0)
	short_night_count = dict.get("short_night_count", 0)
	bad_health_period = dict.get("bad_health_period", 0)
	minion_attack_count = dict.get("minion_attack_count", 0)
	sms_count = dict.get("sms_count", 0)
	unpaid_bill_count = dict.get("unpaid_bill_count", 0)
	update()
