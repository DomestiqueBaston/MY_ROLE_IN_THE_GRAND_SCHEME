@tool
class_name NpcCard extends Card

enum NpcCategory {
	NONE,
	VICTIM,
	SUSPECT,
	WITNESS,
	CULPRIT,
	ACCOMPLICE,
	MINION
}

enum NpcStatus {
	NONE,
	JAIL,
	DEAD,
	DISAPPEARED,
	MINION,
	VICTIM,
	SUSPECT,
	WITNESS,
	CULPRIT,
	ACCOMPLICE
}

enum NpcHealth {
	NONE,
	GOOD,
	AVERAGE,
	LOW
}

enum Sex {
	FEMALE,
	MALE
}

enum SexualOrientation {
	HOMO,
	HETERO
}

##
## The NPC's underlying category, which is NOT visible to the player.
##
@export var category: NpcCategory

##
## The NPC's status, which IS visible to the player.
##
@export var npc_status: NpcStatus:
	set(value):
		npc_status = value
		if is_node_ready():
			_update_appearance()

##
## The NPC's apparent health, which is visible to the player.
##
@export var npc_health: NpcHealth:
	set(value):
		npc_health = value
		if is_node_ready():
			_update_appearance()

##
## NPCs are male or female.
##
@export var npc_sex: Sex:
	set(value):
		npc_sex = value
		if is_node_ready():
			_update_appearance()

@export var is_married: bool:
	set(value):
		is_married = value
		if is_node_ready():
			_update_appearance()

##
## Outline colors, one for each NpcStatus value.
##
@export var outline_colors: Array[Color]

var first_name: String
var last_name: String
var job: String
var job_location: String
var orientation: SexualOrientation
var physical: int
var mental: int
var health: int
var max_health: int
var wanted: int
var player_reputation: int

## Work shifts (a mask of GameState.TimeSlot bits: MORNING, AFTERNOON, EVENING
## and/or NIGHT).
var work_shifts: int

## If true work Wed-Sun, else work Mon-Fri.
var has_weekend_shift: bool

## Which case the NPC belongs to
var _case: Case

## Working day when the NPC was last seen.
var _last_dialogue: int = -1

# Roll of the dice to introduce daily randomness into NPC's location.
var _location_randomness: int = randi()

static var _name_data = preload("res://JSON/NPC/Last_Names_Male_Female_First_Names.json").data
static var _job_data = preload("res://JSON/NPC/NPC_Job.json").data
static var _card_scene = preload("res://SCENES/NPC_Card.tscn")

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func get_card_type():
	return CardType.NPC

func _ready():
	super()
	_update_appearance()

func _update_appearance():
	$Card_Mask/Card_BG/Card_Color/Npc/No_Info.visible = (npc_health == NpcHealth.NONE)
	$Card_Mask/Card_BG/Card_Color/Npc/Good_Health.visible = (npc_health == NpcHealth.GOOD)
	$Card_Mask/Card_BG/Card_Color/Npc/Average_Health.visible = (npc_health == NpcHealth.AVERAGE)
	$Card_Mask/Card_BG/Card_Color/Npc/Low_Health.visible = (npc_health == NpcHealth.LOW)
	$Card_Mask/Card_BG/Jail_Status.visible = (npc_status == NpcStatus.JAIL)
	$Card_Mask/Card_BG/Dead_Status.visible = (npc_status == NpcStatus.DEAD)
	$Card_Mask/Card_BG/Disappeared_Status.visible = (npc_status == NpcStatus.DISAPPEARED)
	$Card_Mask/Card_BG/Minion_Status.visible = (npc_status == NpcStatus.MINION)
	$Card_Mask/Card_BG/Victim_Status.visible = (npc_status == NpcStatus.VICTIM)
	$Card_Mask/Card_BG/Suspect_Status.visible = (npc_status == NpcStatus.SUSPECT)
	$Card_Mask/Card_BG/Witness_Status.visible = (npc_status == NpcStatus.WITNESS)
	$Card_Mask/Card_BG/Culprit_Status.visible = (npc_status == NpcStatus.CULPRIT)
	$Card_Mask/Card_BG/Accomplice_Status.visible = (npc_status == NpcStatus.ACCOMPLICE)
	$Card_Mask/Card_BG/Sex/Male.visible = (npc_sex == Sex.MALE)
	$Card_Mask/Card_BG/Sex/Female.visible = (npc_sex == Sex.FEMALE)
	$Card_Mask/Card_BG/Card_Color/Npc/Couple.visible = is_married
	$Card_Mask/Card_BG/Card_Color/Npc/No_Couple.visible = not is_married
	$Card_Mask/Card_BG/Card_Outlines.self_modulate = outline_colors[npc_status]
	$Card_Drag.modulate = outline_colors[npc_status]

	if not Engine.is_editor_hint():
		tooltip = get_display_name()
		if npc_status != NpcStatus.NONE:
			tooltip += "\n" + NpcStatus.keys()[npc_status].capitalize()

func get_display_name() -> String:
	return first_name + " " + last_name

func get_home() -> LocationCard:
	return get_one_connection(Link.Type.HOME)

func get_work() -> LocationCard:
	return get_one_connection(Link.Type.WORK)

func get_hangout() -> LocationCard:
	return get_one_connection(Link.Type.HANGOUT)

##
## Returns true if the NPC has not been seen yet today.
##
func has_been_seen_today() -> bool:
	return _last_dialogue == GameState.get_working_day()

##
## Updates the NPC's visible health, and flags him as having been seen today.
##
func visit():
	if health >= 8:
		npc_health = NpcHealth.GOOD
	elif health >= 4:
		npc_health = NpcHealth.AVERAGE
	else:
		npc_health = NpcHealth.LOW
	_last_dialogue = GameState.get_working_day()

##
## An NPC who works the night shift sleeps in the morning and the afternoon;
## other NPCs sleep at night.
##
func is_asleep() -> bool:
	var hour = GameState.get_hour()
	if work_shifts & GameState.TimeSlot.NIGHT:
		return hour >= 8 and hour < 16
	else:
		return hour < 8 or hour >= 20

##
## Returns the location where the NPC can be found right now, or null if
## unknown.
##
func locate() -> LocationCard:

	if npc_status in [NpcStatus.DEAD, NpcStatus.DISAPPEARED]:
		return null

	# NPC sleeps at home

	if is_asleep():
		return get_home()

	var hour = GameState.get_hour()

	# each work day there is 1 chance in 10 that the NPC will change his
	# schedule and be at alternative location when he normally works

	if (_location_randomness % 10 == 0) and is_work_day():
		var at_hideout = false

		# night worker: he is off work all night

		if work_shifts & GameState.TimeSlot.NIGHT:
			at_hideout = (hour < 8 or hour >= 20)

		# day worker: he doesn't work one of his two usual shifts

		elif hour >= 8 and hour < 20:
			var off_shift = 0
			var counter = 0
			for shift in [GameState.TimeSlot.MORNING,
						  GameState.TimeSlot.AFTERNOON,
						  GameState.TimeSlot.EVENING]:
				if work_shifts & shift:
					if (_location_randomness % 20) == 0:
						if counter == 0:
							off_shift = shift
					else:
						if counter == 1:
							off_shift = shift
					if off_shift:
						break
					counter += 1
			if hour < 12:
				at_hideout = (off_shift == GameState.TimeSlot.MORNING)
			elif hour < 16:
				at_hideout = (off_shift == GameState.TimeSlot.AFTERNOON)
			else:
				at_hideout = (off_shift == GameState.TimeSlot.EVENING)

		# if the NPC is unexpectedly off work, he can be found at his hideout,
		# if he has one, or at his hangout if not

		if at_hideout:
			return _get_alternative_location()

	# NPC is working

	if should_be_at_work():
		return get_work()

	# 50/50 roll that is independent of the 1 in 10 roll for schedule changes

	@warning_ignore("integer_division")
	var roll = (((_location_randomness / 10) & 1) == 0)

	# NPCs that don't work the night shift spend either the morning or the
	# afternoon at their hideout or hangout, and the rest of the time at home
	# (we know it is not nighttime now because the NPC is not sleeping)

	if (work_shifts & GameState.TimeSlot.NIGHT) == 0 and not is_work_day():
		if hour < 12:
			return get_home() if roll else _get_alternative_location()
		elif hour < 16:
			return get_home() if not roll else _get_alternative_location()
		else:
			return get_home()

	# remaining free time: NPC is either at home or at his hideout or hangout

	return get_home() if roll else _get_alternative_location()

#
# Returns an alternative location where the NPC may be found: either his
# hideout (if he has one, and it is open) or his hangout (if it is open).
#
func _get_alternative_location() -> LocationCard:
	var location = get_one_connection(Link.Type.HIDEOUT)
	if location and location.is_open():
		return location
	location = get_hangout()
	return location if location.is_open() else null

##
## Returns true if the NPC would normally be at work now.
##
func should_be_at_work() -> bool:
	if not is_work_day():
		return false
	var hour = GameState.get_hour()
	if hour < 8 or hour >= 20:
		return (work_shifts & GameState.TimeSlot.NIGHT) != 0
	elif hour < 12:
		return (work_shifts & GameState.TimeSlot.MORNING) != 0
	elif hour < 16:
		return (work_shifts & GameState.TimeSlot.AFTERNOON) != 0
	else:
		return (work_shifts & GameState.TimeSlot.EVENING) != 0

##
## Returns true if today is normally a work day for the NPC: Wednesday to Sunday
## for NPCs that work the weekend shift, Monday to Friday for the others.
##
func is_work_day() -> bool:
	var workday = GameState.get_working_day()
	if has_weekend_shift:
		return workday >= 2
	else:
		return workday < 5

func is_known_to(other: NpcCard) -> bool:
	if other == self:
		return true
	for link_type in [
		Link.Type.FRIEND, Link.Type.ENEMY, Link.Type.ACQUAINTANCE,
		Link.Type.INTIMACY]:
		if other in get_connections(link_type):
			return true
	return false

func _randomize(case: Case, cat: NpcCategory, job_id: String, sex: int):
	category = cat

	# sex and orientation

	if sex >= 0:
		npc_sex = sex as Sex
	else:
		npc_sex = (randi() & 1) as Sex
	if randf() < 0.1:
		orientation = SexualOrientation.HOMO
	else:
		orientation = SexualOrientation.HETERO

	# name

	var _first_names = \
		_name_data["male_first_name" if npc_sex == Sex.MALE else "female_first_name"]
	var _last_names = _name_data["last_name"]
	first_name = _first_names.pick_random()
	last_name = _last_names.pick_random()

	# principal characteristics, randomly assigned between 3 and 7

	const base_points = 15
	physical = randi_range(3, 7)
	var min_men = maxi(3, base_points - physical - 7)
	var max_men = mini(7, base_points - physical - 3)
	mental = randi_range(min_men, max_men)
	max_health = base_points - physical - mental

	# add extra points to principal characteristics at random, limiting to 10

	var extra_points = case.get_difficulty()
	if extra_points > 0:
		var candidates = [&"physical", &"mental", &"max_health"]
		for i in extra_points:
			var attr_index = randi() % candidates.size()
			var attr_name = candidates[attr_index]
			set(attr_name, get(attr_name) + 1)
			if get(attr_name) == 10:
				candidates.remove_at(attr_index)

	# job and corresponding bonus/malus for principal characteristics

	if job_id.is_empty():
		job_id = _job_data.keys().pick_random()
	var job_info = _job_data[job_id]
	job = job_info["name"]
	job_location = job_info["work_place"].pick_random()
	var bonus_malus = job_info["bonus_malus"]
	if bonus_malus is Array:
		bonus_malus = bonus_malus.pick_random()
	if bonus_malus is Dictionary:
		physical += bonus_malus.get("PHY", 0)
		mental += bonus_malus.get("MEN", 0)
		max_health += bonus_malus.get("HEA", 0)

	# work shifts

	var night_prob = job_info.get("night_shift_chance", 0.0)
	var weekend_prob = job_info.get("weekend_shift_chance", 0.0)
	var work_night = (randf() <= night_prob) if night_prob > 0.0 else false

	has_weekend_shift = (randf() <= weekend_prob) if weekend_prob > 0.0 else false

	if work_night:
		work_shifts = GameState.TimeSlot.NIGHT
	else:
		var roll = randi() % 3
		if roll != 0:
			work_shifts |= GameState.TimeSlot.MORNING
		if roll != 1:
			work_shifts |= GameState.TimeSlot.AFTERNOON
		if roll != 2:
			work_shifts |= GameState.TimeSlot.EVENING

	# initial health, wanted, etc.

	health = roundi(max_health * randf_range(0.5, 1.0))
	wanted = randi_range(0, 2)
	player_reputation = -2 if category == NpcCategory.MINION else 0

	# not all NPCs have a hideout location

	var hideout_probability
	if category in [NpcCategory.CULPRIT, NpcCategory.ACCOMPLICE]:
		hideout_probability = 0.8
	else:
		hideout_probability = 0.4
	if randf() < hideout_probability:
		var hideout = case.create_hideout()
		Card.add_bidirectional_connection(Link.Type.HIDEOUT, self, hideout)

##
## Call this at the start of each new day to update the NPC's health and/or
## location.
##
func new_day():
	var yesterday = GameState.get_working_day() - 1

	if _last_dialogue < yesterday:

		# each day the NPC has not interacted with the player, there is a 10%
		# chance one of PHY, MEN or maxHEA will change

		match randi() % 6:
			0:
				physical += 1
				print("%s: PHY +1" % get_display_name())
			1:
				physical -= 1
				print("%s: PHY -1" % get_display_name())
			2:
				mental += 1
				print("%s: MEN +1" % get_display_name())
			3:
				mental -= 1
				print("%s: MEN -1" % get_display_name())
			4:
				max_health += 1
				print("%s: maxHEA +1" % get_display_name())
			5:
				max_health -= 1
				health = mini(health, max_health)
				print("%s: maxHEA -1" % get_display_name())

		# the player's reputation increases by 1 every N days without interaction,
		# where N is the difficulty of the case

		if _case and npc_status != NpcStatus.MINION and player_reputation < 2:
			var difficulty = maxi(1, _case.get_difficulty())
			if (yesterday - _last_dialogue - 1) % difficulty == difficulty - 1:
				player_reputation += 1
				print("%s: Rep +1" % get_display_name())

	# the NPC's health is incremented until it reaches max_health (perhaps this
	# should be done at different times depending on his work schedules)

	if health < max_health:
		health += 1
		print("%s: HEA +1" % get_display_name())

	# introduce a bit of randomness into the NPC's schedule

	_location_randomness = randi()

##
## Generates and returns a random non-playing character for a case.
##
## The case is necessary because we need to know its difficulty, and because any
## locations generated are registered with the case.
##
## If possible_jobs is given, it is an array of job IDs, one of which is chosen
## at random for the NPC's profession. If it is not given or is empty, the NPC
## may be given any job.
##
## Note that the new character may be given a hideout, since hideouts are never
## shared, but he will NOT be given a home, a place of work or a hangout. They
## must be assigned later.
##
static func generate_card(
	case: Case, cat: NpcCategory = NpcCategory.NONE, possible_jobs = [],
	sex: int = -1) -> NpcCard:
	var card = _card_scene.instantiate()
	card._case = case
	var job_id: String
	if possible_jobs:
		job_id = possible_jobs.pick_random()
	card._randomize(case, cat, job_id, sex)
	return card

func print_npc():
	if category == NpcCategory.NONE:
		print("%s:" % get_display_name())
	else:
		print("%s (%s):" % [get_display_name(), NpcCategory.keys()[category].to_lower()])
	print("  sex: %s (%s)" % [
		Sex.keys()[npc_sex].to_lower(),
		SexualOrientation.keys()[orientation].to_lower()])
	print("  married: ", is_married)
	print("  job: ", job)
	print_connections_of_type("home", Link.Type.HOME)
	print_connections_of_type("work", Link.Type.WORK)
	print_connections_of_type("hangout", Link.Type.HANGOUT)
	print_connections_of_type("hideout", Link.Type.HIDEOUT)
	print_connections_of_type("intimates", Link.Type.INTIMACY)
	print_connections_of_type("friends", Link.Type.FRIEND)
	print_connections_of_type("enemies", Link.Type.ENEMY)
	print_connections_of_type("acquaintances", Link.Type.ACQUAINTANCE)
	print_connections_of_type("property", Link.Type.PROPERTY)
	print_connections_of_type("debt", Link.Type.DEBT)
	print_connections_of_type("ideology", Link.Type.IDEOLOGY)

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.NPC_CARD

#
# For save/load.
#
func get_unique_id():
	return "npc%d" % _unique_id

#
# For save/load.
#
func get_referenced_objects():
	var refs = super()
	if _case:
		refs.append(_case)
	return refs

#
# For save/load.
#
func get_json_dict():
	var dict = super()
	dict["category"] = category
	dict["status"] = npc_status
	dict["npc_health"] = npc_health
	dict["sex"] = npc_sex
	if is_married:
		dict["is_married"] = is_married
	dict["first_name"] = first_name
	dict["last_name"] = last_name
	dict["job"] = job
	dict["job_location"] = job_location
	dict["orientation"] = orientation
	dict["physical"] = physical
	dict["mental"] = mental
	dict["health"] = health
	dict["max_health"] = max_health
	dict["wanted"] = wanted
	if player_reputation != 0:
		dict["player_reputation"] = player_reputation
	dict["work_shifts"] = work_shifts
	if has_weekend_shift:
		dict["has_weekend_shift"] = has_weekend_shift
	if _last_dialogue >= 0:
		dict["last_dialogue"] = _last_dialogue
	if _case:
		dict["case"] = _case.get_unique_id()
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	category = dict.category
	npc_status = dict.status
	npc_health = dict.npc_health
	npc_sex = dict.sex
	is_married = dict.get("is_married", false)
	first_name = dict.first_name
	last_name = dict.last_name
	job = dict.job
	job_location = dict.job_location
	npc_sex = dict.sex
	orientation = dict.orientation
	physical = dict.physical
	mental = dict.mental
	max_health = dict.max_health
	health = dict.health
	wanted = dict.wanted
	player_reputation = dict.get("player_reputation", 0)
	work_shifts = dict.get("work_shifts", 0)
	has_weekend_shift = dict.get("has_weekend_shift", false)
	_last_dialogue = dict.get("last_dialogue", -1)
	if "case" in dict:
		_case = catalog[dict.case]

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
