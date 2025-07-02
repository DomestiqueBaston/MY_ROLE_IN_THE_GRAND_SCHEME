class_name NPC extends Node

enum Sex {
	FEMALE,
	MALE
}

enum SexualOrientation {
	HOMO,
	HETERO
}

var first_name: String
var last_name: String
var job: Dictionary
var sex: Sex
var orientation: SexualOrientation
var physical: int
var mental: int
var health: int
var max_health: int
var wanted: int
var is_minion: bool
var player_reputation: int
var home: Card
var work: Card

var _name_data = preload("res://JSON/NPC/Last_Names_Male_Female_First_Names.json").data
var _job_data = preload("res://JSON/NPC/NPC_Job.json").data
var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
var _card_scene = preload("res://SCENES/Card.tscn")

static func generate(
	extra_points: int = 0, profession = {}, minion: bool = false) -> NPC:
	var npc = NPC.new()
	npc._randomize(extra_points, profession, minion)
	return npc

func _randomize(extra_points: int, profession: Dictionary, minion: bool):

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

	# principal characteristics, randomly assigned between 3 and 7

	const base_points = 15
	physical = randi_range(3, 7)
	var min_men = maxi(3, base_points - physical - 7)
	var max_men = mini(7, base_points - physical - 3)
	mental = randi_range(min_men, max_men)
	max_health = base_points - physical - mental

	# add extra points to principal characteristics at random, limiting to 10

	if extra_points > 0:
		var candidates = [&"physical", &"mental", &"max_health"]
		for i in extra_points:
			var attr_index = randi() % candidates.size()
			var attr_name = candidates[attr_index]
			set(attr_name, get(attr_name) + 1)
			if get(attr_name) == 10:
				candidates.remove_at(attr_index)

	# job and corresponding bonus/malus for principal characteristics

	job = profession if profession else _job_data[randi() % _job_data.size()]

	var bonus_malus = job.get("bonus_malus")
	if bonus_malus is Array:
		bonus_malus = bonus_malus[randi() % bonus_malus.size()]
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

	home = _card_scene.instantiate()
	home.card_type = Card.CardType.LOCATION
	home.other_info = _location_data["LOC001"]
	home.card_name = "%s's Apartment" % first_name

	var work_place_list = job["work_place"]
	var work_index = randi() % work_place_list.size()
	work = _card_scene.instantiate()
	work.card_type = Card.CardType.LOCATION
	work.other_info = _location_data[work_place_list[work_index]]
	work.card_name = "%s's Workplace" % first_name
