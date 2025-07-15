@tool
class_name NpcCard extends BaseCard

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

static var _name_data = preload("res://JSON/NPC/Last_Names_Male_Female_First_Names.json").data
static var _job_data = preload("res://JSON/NPC/NPC_Job.json").data
static var _card_scene = preload("res://SCENES/NPC_Card.tscn")

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
	var tooltip = NpcStatus.keys()[npc_status].capitalize()
	$Card_Mask/Card_BG/Card_Text/Card_Name.tooltip_text = tooltip
	$Card_Mask/Card_BG/Card_Text/Card_Description.tooltip_text = tooltip

func get_display_name() -> String:
	return first_name + " " + last_name

func get_home() -> LocationCard:
	var cnxs = get_connections(Link.Type.HOME)
	return null if cnxs.is_empty() else cnxs[0]

func get_work() -> LocationCard:
	var cnxs = get_connections(Link.Type.WORK)
	return null if cnxs.is_empty() else cnxs[0]

func get_hangout() -> LocationCard:
	var cnxs = get_connections(Link.Type.HANGOUT)
	return null if cnxs.is_empty() else cnxs[0]

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
	first_name = _first_names[randi() % _first_names.size()]
	last_name = _last_names[randi() % _last_names.size()]

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

	# initial health, wanted, etc.

	health = roundi(max_health * randf_range(0.5, 1.0))
	wanted = randi_range(0, 2)
	player_reputation = -2 if category == NpcCategory.MINION else 0

	# everyone has a hangout location

	var hangout = case.find_hangout()
	add_connection(Link.Type.HANGOUT, hangout)
	hangout.add_connection(Link.Type.HANGOUT, self)

	# not all NPCs have a hideout location

	var hideout_probability
	if category in [NpcCategory.CULPRIT, NpcCategory.ACCOMPLICE]:
		hideout_probability = 0.8
	else:
		hideout_probability = 0.4
	if randf() < hideout_probability:
		var hideout = case.create_hideout()
		add_connection(Link.Type.HIDEOUT, hideout)
		hideout.add_connection(Link.Type.HIDEOUT, self)

##
## Call this at the start of each new day: the NPC's health is incremented
## until it reaches max_health. (Perhaps this should be done at different times
## depending on NPCs' work schedules?)
##
func new_day():
	if health < max_health:
		health += 1

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
## Note that the new character is given a hangout and possibly a hideout, but
## NOT a home or a place of work. They must be assigned later.
##
static func generate_card(
	case: Case, cat: NpcCategory = NpcCategory.NONE, possible_jobs = [],
	sex: int = -1) -> NpcCard:
	var card = _card_scene.instantiate()
	var job_id: String
	if possible_jobs:
		job_id = possible_jobs.pick_random()
	card._randomize(case, cat, job_id, sex)
	return card

func print_npc():
	print("%s:" % get_display_name())
	print("  category: ", NpcCategory.keys()[category].to_lower())
	print("  sex: %s (%s)" % [
		Sex.keys()[npc_sex].to_lower(),
		SexualOrientation.keys()[orientation].to_lower()])
	print("  married: ", is_married)
	print("  job: ", job)
	_print_connections_of_type("home", Link.Type.HOME)
	_print_connections_of_type("work", Link.Type.WORK)
	_print_connections_of_type("hangout", Link.Type.HANGOUT)
	_print_connections_of_type("hideout", Link.Type.HIDEOUT)
	_print_connections_of_type("intimates", Link.Type.INTIMACY)
	_print_connections_of_type("friends", Link.Type.FRIEND)
	_print_connections_of_type("enemies", Link.Type.ENEMY)
	_print_connections_of_type("acquaintances", Link.Type.ACQUAINTANCE)
	_print_connections_of_type("property", Link.Type.PROPERTY)

func _print_connections_of_type(label: String, type: Link.Type):
	var cnxs = get_connections(type)
	if cnxs:
		var text = ""
		for cnx in cnxs:
			if not text.is_empty():
				text += ", "
			text += cnx.get_display_name()
		print("  ", label, ": ", text)
	else:
		print("  ", label, ": none")

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.NPC_CARD

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

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
