@tool
class_name NpcCard extends BaseCard

enum NpcHealth {
	NONE,
	GOOD,
	AVERAGE,
	LOW
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

enum Sex {
	FEMALE,
	MALE
}

enum SexualOrientation {
	HOMO,
	HETERO
}

@export var npc_health: NpcHealth:
	set(value):
		npc_health = value
		if is_node_ready():
			_update_background()

@export var npc_status: NpcStatus:
	set(value):
		npc_status = value
		if is_node_ready():
			_update_background()

@export var npc_sex: Sex:
	set(value):
		npc_sex = value
		if is_node_ready():
			_update_background()

var first_name: String
var last_name: String
var job: String
var sex: Sex
var orientation: SexualOrientation
var physical: int
var mental: int
var health: int
var max_health: int
var wanted: int
var is_minion: bool
var player_reputation: int

var _home: WeakRef
var _work: WeakRef

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

func _randomize(case: Case, job_id: String, minion: bool):

	# sex and orientation

	sex = (randi() & 1) as Sex
	if randf() < 0.1:
		orientation = SexualOrientation.HOMO
	else:
		orientation = SexualOrientation.HETERO

	# name

	var _first_names = \
		_name_data["male_first_name" if sex == Sex.MALE else "female_first_name"]
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
	is_minion = minion
	player_reputation = -2 if is_minion else 0

	# home and work locations

	var home = case.create_location("LOC001")
	home.add_inhabitant(self)
	_home = weakref(home)

	var work_place = job_info["work_place"].pick_random()
	var work
	if work_place == "LOC001":
		work = case.create_location("LOC001")
	else:
		work = case.find_or_create_location(work_place)
	_work = weakref(work)

static func generate_card(
		case: Case, possible_jobs = [], minion: bool = false) -> NpcCard:
	var card = _card_scene.instantiate()
	var job_id: String
	if possible_jobs:
		job_id = possible_jobs.pick_random()
	card._randomize(case, job_id, minion)
	return card

func get_custom_class():
	return SaveLoadTools.Class.NPC_CARD

func get_referenced_objects():
	var refs = super()
	if _home:
		refs.append(_home.get_ref())
	if _work:
		refs.append(_work.get_ref())
	return refs

func get_json_dict():
	var dict = super()
	dict["first_name"] = first_name
	dict["last_name"] = last_name
	dict["job"] = job
	dict["sex"] = sex
	dict["orientation"] = orientation
	dict["physical"] = physical
	dict["mental"] = mental
	dict["health"] = health
	dict["max_health"] = max_health
	dict["wanted"] = wanted
	if is_minion:
		dict["is_minion"] = is_minion
	if player_reputation != 0:
		dict["player_reputation"] = player_reputation
	if _home:
		dict["home"] = SaveLoadTools.get_object_id(_home.get_ref())
	if _work:
		dict["work"] = SaveLoadTools.get_object_id(_work.get_ref())
	return dict

func restore(dict, catalog):
	super(dict, catalog)
	first_name = dict.first_name
	last_name = dict.last_name
	job = dict.job
	sex = dict.sex
	orientation = dict.orientation
	physical = dict.physical
	mental = dict.mental
	max_health = dict.max_health
	health = dict.health
	wanted = dict.wanted
	is_minion = dict.get("is_minion", false)
	player_reputation = dict.get("player_reputation", 0)
	card_name = first_name + " " + last_name
	if "home" in dict:
		_home = weakref(catalog[dict.home])
	if "work" in dict:
		_work = weakref(catalog[dict.work])

static func allocate() -> Object:
	return _card_scene.instantiate()
