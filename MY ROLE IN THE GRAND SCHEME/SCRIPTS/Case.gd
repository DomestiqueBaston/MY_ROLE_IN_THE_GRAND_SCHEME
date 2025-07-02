class_name Case extends Node

var crime: String
var motive: Dictionary
var location: Dictionary
var duration: int
var difficulty: int
var paused: bool = false

var culprits: Array[Card]
var victims: Array[Card]
var witnesses: Array[Card]
var accomplices: Array[Card]
var suspects: Array[Card]
var other_npcs: Array[Card]
var evidence: Array[Card]
var crime_location: Card

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data
var _job_data = preload("res://JSON/NPC/NPC_Job.json").data
var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data
var _card_scene = preload("res://SCENES/Card.tscn")

static func generate() -> Case:
	var case = Case.new()
	case._randomize()
	return case

func _randomize():

	# crime

	crime = GameState.get_new_crime()

	# motive (and lots of other information about the case)

	var motive_list = _crime_data[crime]
	var motive_index = randi() % motive_list.size()
	motive = motive_list[motive_index]

	# NPCs: culprits

	culprits = _generate_npcs(
		motive.get("culprits", 0), Card.NpcStatus.NONE,
		motive.get("culprits_professions", []))

	# NPCs: victims

	victims = _generate_npcs(
		motive.get("victims", 0), Card.NpcStatus.VICTIM,
		motive.get("victims_professions", []))

	if victims:
		var dead = motive["dead_victims"]
		for card in victims:
			if dead == "yes":
				card.npc_status = Card.NpcStatus.DEAD
			elif dead == "disappeared":
				card.npc_status = Card.NpcStatus.DISAPPEARED
			elif dead == "random":
				if randi() & 1:
					card.npc_status = Card.NpcStatus.DEAD

	# NPCs: witnesses, accomplices, suspects

	witnesses = _generate_npcs(motive.get("witnesses", 0), Card.NpcStatus.WITNESS)
	accomplices = _generate_npcs(motive.get("accomplices", 0))
	suspects = _generate_npcs(motive.get("suspects", 0), Card.NpcStatus.SUSPECT)

	# evidence

	var evidence_count = motive.get("evidence_number", 0)
	if evidence_count is Array and not evidence_count.is_empty():
		evidence_count = evidence_count[randi() % evidence_count.size()]
	evidence_count = maxi(evidence_count, culprits.size())
	evidence.clear()

	if evidence_count > 0:
		var candidates = motive.get("evidences", []).duplicate()
		evidence_count = mini(evidence_count, candidates.size() - 1)
		for i in evidence_count:
			var card = _card_scene.instantiate()
			card.card_type = Card.CardType.OBJECT
			#card.is_object_evidence = true
			var which = randi() % candidates.size()
			var obj_info = _object_data[candidates[which]]
			card.card_name = obj_info["name"]
			card.description = obj_info["description"]
			candidates.remove_at(which)
			evidence.append(card)

	# TODO: links
	# TODO: difficulty += number of links * 0.5

	var diff = 19.0/50.0 * (1.0
		+ culprits.size()
		+ victims.size()
		+ accomplices.size() * 0.5
		- suspects.size() * 0.5
		- witnesses.size() * 0.5
		+ evidence.size())
	difficulty = clampi(roundi(diff), 1, 5)

	# NPCs unrelated to the case

	var useless_count
	match difficulty:
		0:
			useless_count = randi_range(2, 3)
		1:
			useless_count = randi_range(3, 5)
		2:
			useless_count = randi_range(5, 9)
		3:
			useless_count = randi_range(8, 13)
		4:
			useless_count = randi_range(11, 16)
		5:
			useless_count = randi_range(13, 19)
		6:
			useless_count = randi_range(15, 22)
	other_npcs = _generate_npcs(useless_count)

	# crime location

	var location_name = motive["crime_location"]
	if location_name is Array and not location_name.is_empty():
		location_name = location_name[randi() % location_name.size()]

	var actual_location

	if location_name.begins_with("any"):
		var is_any_culprit
		if location_name == "any_culprit":
			is_any_culprit = true
		elif location_name == "any_victim":
			is_any_culprit = false
		else:
			is_any_culprit = ((randi() & 1) == 1)
		actual_location = "home" if randi() & 1 else "work"
		if is_any_culprit:
			actual_location = "culprit_" + actual_location
	else:
		actual_location = location_name

	crime_location = null
	var location_card: Card

	if actual_location == "none":
		location_card = null
	elif actual_location == "home":
		location_card = victims[0].extra_data.home
	elif actual_location == "work":
		location_card = victims[0].extra_data.work
	elif actual_location == "culprit_home":
		location_card = culprits[0].extra_data.home
	elif actual_location == "culprit_work":
		location_card = culprits[0].extra_data.work
	else:
		crime_location = _card_scene.instantiate()
		crime_location.card_type = Card.CardType.LOCATION
		crime_location.other_info = _location_data[actual_location]
		crime_location.card_name = crime_location.other_info["name"]
		location_card = crime_location

	if location_card:
		var known_factor = motive.get("known_crime_location", 1)
		var is_known
		if known_factor <= 0:
			is_known = false
		elif known_factor >= 1:
			is_known = true
		else:
			is_known = (randf() < known_factor)
		if is_known:
			location_card.location_status = Card.LocationStatus.CRIME_SCENE

func _generate_npcs(count, status = Card.NpcStatus.NONE, job_list = []) -> Array[Card]:
	var cards: Array[Card]
	if count is Array and not count.is_empty():
		count = count[randi() % count.size()]
	if count > 0:
		var job_id = _get_npc_job(job_list)
		var card: Card = _card_scene.instantiate()
		var extra: NPC = NPC.generate(0, _job_data[job_id])
		card.card_type = Card.CardType.NPC
		card.npc_status = status
		card.npc_sex = extra.sex
		card.extra_data = extra
		card.card_name = extra.first_name + " " + extra.last_name
		cards.append(card)
	return cards

func _get_npc_job(job_list: Array):
	if job_list.is_empty():
		return _job_data.keys()[randi() % _job_data.size()]
	else:
		return job_list[randi() % job_list.size()]

func get_cards() -> Array[Card]:
	var all_cards: Array[Card]
	for npcs in [culprits, victims, witnesses, accomplices, suspects, other_npcs]:
		all_cards.append_array(npcs)
		for npc in npcs:
			all_cards.append(npc.extra_data.home)
			all_cards.append(npc.extra_data.work)
	all_cards.append_array(evidence)
	if crime_location:
		all_cards.append(crime_location)
	return all_cards

# TODO: function to return links
