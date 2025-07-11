@tool
class_name NpcCard extends BaseCard

enum NpcCategory {
	NONE,
	USELESS,
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
			_update_background()

##
## The NPC's apparent health, which is visible to the player.
##
@export var npc_health: NpcHealth:
	set(value):
		npc_health = value
		if is_node_ready():
			_update_background()

##
## NPCs are male or female.
##
@export var npc_sex: Sex:
	set(value):
		npc_sex = value
		if is_node_ready():
			_update_background()

var first_name: String
var last_name: String
var job: String
var orientation: SexualOrientation
var physical: int
var mental: int
var health: int
var max_health: int
var wanted: int
var player_reputation: int

var _home: WeakRef
var _work: WeakRef
var _hangout: WeakRef
var _hideout: WeakRef

static var _name_data = preload("res://JSON/NPC/Last_Names_Male_Female_First_Names.json").data
static var _job_data = preload("res://JSON/NPC/NPC_Job.json").data
static var _card_scene = preload("res://SCENES/NPC_Card.tscn")

func get_card_type():
	return CardType.NPC

func _ready():
	super()
	_update_background()

func _update_background():
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

func get_home() -> LocationCard:
	return _home.get_ref()

func get_work() -> LocationCard:
	return _work.get_ref()

func _randomize(case: Case, cat: NpcCategory, job_id: String):
	category = cat

	# sex and orientation

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
	card_name = first_name + " " + last_name

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

	# home and work locations

	var home = case.create_location("LOC001", self)
	_home = weakref(home)

	var work_place = job_info["work_place"].pick_random()
	var work
	if work_place == "LOC001":
		work = case.create_location("LOC001", self)
	else:
		work = case.find_or_create_location(work_place, self)
	_work = weakref(work)

	# everyone has a hangout location

	_hangout = weakref(case.find_hangout(self))

	# not all NPCs have a hideout location

	var hideout_probability
	match category:
		NpcCategory.USELESS:
			hideout_probability = 0.2
		NpcCategory.CULPRIT, NpcCategory.ACCOMPLICE:
			hideout_probability = 0.8
		_:
			hideout_probability = 0.5
	if randf() < hideout_probability:
		_hideout = weakref(case.create_hideout(self))
	else:
		_hideout = null

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
static func generate_card(
	case: Case, cat: NpcCategory, possible_jobs = []) -> NpcCard:
	var card = _card_scene.instantiate()
	var job_id: String
	if possible_jobs:
		job_id = possible_jobs.pick_random()
	card._randomize(case, cat, job_id)
	return card

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.NPC_CARD

#
# For save/load.
#
func get_referenced_objects():
	var refs = super()
	if _home:
		refs.append(_home.get_ref())
	if _work:
		refs.append(_work.get_ref())
	if _hangout:
		refs.append(_hangout.get_ref())
	if _hideout:
		refs.append(_hideout.get_ref())
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
	dict["first_name"] = first_name
	dict["last_name"] = last_name
	dict["job"] = job
	dict["orientation"] = orientation
	dict["physical"] = physical
	dict["mental"] = mental
	dict["health"] = health
	dict["max_health"] = max_health
	dict["wanted"] = wanted
	if player_reputation != 0:
		dict["player_reputation"] = player_reputation
	if _home:
		dict["home"] = SaveLoadTools.get_object_id(_home.get_ref())
	if _work:
		dict["work"] = SaveLoadTools.get_object_id(_work.get_ref())
	if _hangout:
		dict["hangout"] = SaveLoadTools.get_object_id(_hangout.get_ref())
	if _hideout:
		dict["hideout"] = SaveLoadTools.get_object_id(_hideout.get_ref())
	return dict

#
# For save/load.
#
func restore(dict, catalog):
	super(dict, catalog)
	category = dict.get("category", NpcCategory.NONE)
	npc_status = dict.get("status", NpcStatus.NONE)
	npc_health = dict.get("npc_health", NpcHealth.NONE)
	npc_sex = dict.sex
	first_name = dict.first_name
	last_name = dict.last_name
	job = dict.job
	npc_sex = dict.sex
	orientation = dict.orientation
	physical = dict.physical
	mental = dict.mental
	max_health = dict.max_health
	health = dict.health
	wanted = dict.wanted
	player_reputation = dict.get("player_reputation", 0)
	card_name = first_name + " " + last_name
	if "home" in dict:
		_home = weakref(catalog[dict.home])
	if "work" in dict:
		_work = weakref(catalog[dict.work])
	if "hangout" in dict:
		_hangout = weakref(catalog[dict.hangout])
	if "hideout" in dict:
		_hideout = weakref(catalog[dict.hideout])

#
# For save/load.
#
static func allocate() -> Object:
	return _card_scene.instantiate()
