class_name Case extends RefCounted

enum Status {
	UNASSIGNED,
	ACTIVE,
	PAUSED,
	DONE
}

var culprits: Array[NpcCard]
var victims: Array[NpcCard]
var witnesses: Array[NpcCard]
var accomplices: Array[NpcCard]
var suspects: Array[NpcCard]
var other_npcs: Array[NpcCard]
var evidence: Array[ObjectCard]
var crime_location: LocationCard

var _case_id: String
var _case_name: String
var _crime: String
var _motive: Dictionary
var _difficulty: int
var _duration: int
var _status: Status = Status.UNASSIGNED
var _links: Array[Link]

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

func _notification(what: int):

	# Cards and Links are Nodes, not RefCounted, so they must be deleted
	# explicitly. But note that Pins are deleted automatically when the Link
	# connecting them is deleted.

	if what == NOTIFICATION_PREDELETE:
		for card_list in [
			culprits, victims, witnesses, accomplices, suspects, other_npcs,
			evidence
		]:
			for card in card_list:
				card.queue_free()
			card_list.clear()

		if crime_location:
			crime_location.queue_free()
			crime_location = null

		for link in _links:
			link.queue_free()
		_links.clear()

static func generate() -> Case:
	var case = Case.new()
	case._randomize()
	return case

func _randomize():
	_case_id = _generate_case_id()

	# crime, motive and lots of other information about the case

	_crime = GameState.get_new_crime()
	_motive = _crime_data[_crime].pick_random()
	_case_name = _motive["name"]

	# NPCs: culprits

	culprits = _generate_npcs(
		_motive.get("culprits", 0), NpcCard.NpcStatus.NONE,
		_motive.get("culprits_professions", []))

	# NPCs: victims

	victims = _generate_npcs(
		_motive.get("victims", 0), NpcCard.NpcStatus.VICTIM,
		_motive.get("victims_professions", []))

	if victims:
		var dead = _motive["dead_victims"]
		for card in victims:
			if dead == "yes":
				card.npc_status = NpcCard.NpcStatus.DEAD
			elif dead == "disappeared":
				card.npc_status = NpcCard.NpcStatus.DISAPPEARED
			elif dead == "random":
				if randi() & 1:
					card.npc_status = NpcCard.NpcStatus.DEAD

	# NPCs: witnesses, accomplices, suspects

	witnesses = _generate_npcs(
		_motive.get("witnesses", 0), NpcCard.NpcStatus.WITNESS)
	accomplices = _generate_npcs(
		_motive.get("accomplices", 0))
	suspects = _generate_npcs(
		_motive.get("suspects", 0), NpcCard.NpcStatus.SUSPECT)

	# evidence

	var evidence_count = _motive.get("evidence_number", 0)
	if evidence_count is Array and not evidence_count.is_empty():
		evidence_count = evidence_count.pick_random()
	evidence_count = maxi(evidence_count, culprits.size())
	evidence.clear()

	if evidence_count > 0:
		var candidates = _motive.get("evidences", []).duplicate()
		evidence_count = mini(evidence_count, candidates.size() - 1)
		for i in evidence_count:
			var which = randi() % candidates.size()
			var card = ObjectCard.create_card(candidates[which])
			# TODO: set location and owner?
			candidates.remove_at(which)
			evidence.append(card)

	# TODO: links
	# TODO: difficulty += number of links * 0.5
	# TODO: useless objects

	var diff = 19.0/50.0 * (1.0
		+ culprits.size()
		+ victims.size()
		+ accomplices.size() * 0.5
		- suspects.size() * 0.5
		- witnesses.size() * 0.5
		+ evidence.size())
	_difficulty = clampi(roundi(diff), 1, 5)

	if _difficulty == 6:
		_duration = 15 + randi_range(-2, 2)
	else:
		_duration = roundi((_difficulty * 4 + 10) * randf_range(0.9, 1.1))

	# NPCs unrelated to the case

	var useless_count
	match _difficulty:
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

	var location_name = _motive["crime_location"]
	if location_name is Array and not location_name.is_empty():
		location_name = location_name.pick_random()

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
	var location_card: LocationCard

	if actual_location == "none":
		location_card = null
	elif actual_location == "home":
		location_card = victims[0].get_home()
	elif actual_location == "work":
		location_card = victims[0].get_work()
	elif actual_location == "culprit_home":
		location_card = culprits[0].get_home()
	elif actual_location == "culprit_work":
		location_card = culprits[0].get_work()
	else:
		crime_location = LocationCard.create_card(actual_location)
		location_card = crime_location

	if location_card:
		var known_factor = _motive.get("known_crime_location", 1)
		var is_known
		if known_factor <= 0:
			is_known = false
		elif known_factor >= 1:
			is_known = true
		else:
			is_known = (randf() < known_factor)
		if is_known:
			location_card.location_status = LocationCard.LocationStatus.CRIME_SCENE

func _generate_npcs(
		count, npc_status = NpcCard.NpcStatus.NONE, job_list = []) -> Array[NpcCard]:
	var cards: Array[NpcCard]
	if count is Array and not count.is_empty():
		count = count.pick_random()
	for i in count:
		var card = NpcCard.generate_card(0, job_list)
		card.npc_status = npc_status
		cards.append(card)
	return cards

func _generate_case_id():
	# [A-Z][a-z]
	var part1 = char(randi_range(65, 90)) + char(randi_range(97, 122))

	# 01-99
	var part2 = "%02d" % randi_range(1, 99)

	# [A-Z][a-z][1-9]
	var part3 = char(randi_range(65, 90)) + char(randi_range(97, 122)) \
			  + str(randi_range(1, 9))

	# 1-9
	var part4 = str(randi_range(1, 9))

	return "%s#%s-%s.%s" % [part1, part2, part3, part4]

func get_case_id() -> String:
	return _case_id

func get_case_name() -> String:
	return _case_name

func get_status() -> Status:
	return _status

func get_difficulty() -> int:
	return _difficulty

func get_duration() -> int:
	return _duration

func get_cards() -> Array[BaseCard]:
	var all_cards: Array[BaseCard]
	for npcs in [
		culprits, victims, witnesses, accomplices, suspects, other_npcs
	]:
		all_cards.append_array(npcs)
		for npc in npcs:
			all_cards.append(npc.get_home())
			all_cards.append(npc.get_work())
	all_cards.append_array(evidence)
	if crime_location:
		all_cards.append(crime_location)
	return all_cards

func add_link(link: Link):
	_links.append(link)

func remove_link(link: Link):
	_links.erase(link)

func get_links() -> Array[Link]:
	return _links

func start():
	_status = Status.ACTIVE

func pause():
	_status = Status.PAUSED

func get_custom_class():
	return SaveLoadTools.Class.CASE

func get_referenced_objects():
	var refs = []
	refs.append_array(culprits)
	refs.append_array(victims)
	refs.append_array(witnesses)
	refs.append_array(accomplices)
	refs.append_array(suspects)
	refs.append_array(other_npcs)
	refs.append_array(evidence)
	if crime_location:
		refs.append(crime_location)
	refs.append_array(_links)
	return refs

func get_json_dict():
	var dict = {
		"case_id": _case_id,
		"case_name": _case_name,
		"crime": _crime,
		"motive": _motive,
		"difficulty": _difficulty,
		"duration": _duration,
		"status": _status
	}

	if culprits:
		var culprit_refs = []
		for card in culprits:
			culprit_refs.append(SaveLoadTools.get_object_id(card))
		dict["culprits"] = culprit_refs

	if victims:
		var victim_refs = []
		for card in victims:
			victim_refs.append(SaveLoadTools.get_object_id(card))
		dict["victims"] = victim_refs

	if witnesses:
		var witness_refs = []
		for card in witnesses:
			witness_refs.append(SaveLoadTools.get_object_id(card))
		dict["witnesses"] = witness_refs

	if accomplices:
		var accomplice_refs = []
		for card in accomplices:
			accomplice_refs.append(SaveLoadTools.get_object_id(card))
		dict["accomplices"] = accomplice_refs

	if suspects:
		var suspect_refs = []
		for card in suspects:
			suspect_refs.append(SaveLoadTools.get_object_id(card))
		dict["suspects"] = suspect_refs

	if other_npcs:
		var other_npc_refs = []
		for card in other_npcs:
			other_npc_refs.append(SaveLoadTools.get_object_id(card))
		dict["other_npcs"] = other_npc_refs

	if evidence:
		var evidence_refs = []
		for card in evidence:
			evidence_refs.append(SaveLoadTools.get_object_id(card))
		dict["evidence"] = evidence_refs

	if crime_location:
		dict["crime_location"] = SaveLoadTools.get_object_id(crime_location)

	if _links:
		var link_refs = []
		for link in _links:
			link_refs.append(SaveLoadTools.get_object_id(link))
		dict["links"] = link_refs

	return dict

func restore(dict, catalog):
	_case_id = dict.get("case_id", "")
	_case_name = dict.case_name
	_crime = dict.crime
	_motive = dict.motive
	_difficulty = dict.difficulty
	_duration = dict.duration
	_status = dict.status
	for ref in dict.get("culprits", []):
		culprits.append(catalog[ref])
	for ref in dict.get("victims", []):
		victims.append(catalog[ref])
	for ref in dict.get("witnesses", []):
		witnesses.append(catalog[ref])
	for ref in dict.get("accomplices", []):
		accomplices.append(catalog[ref])
	for ref in dict.get("suspects", []):
		suspects.append(catalog[ref])
	for ref in dict.get("other_npcs", []):
		other_npcs.append(catalog[ref])
	for ref in dict.get("evidence", []):
		evidence.append(catalog[ref])
	if "crime_location" in dict:
		crime_location = catalog[dict.crime_location]
	for ref in dict.get("links", []):
		_links.append(catalog[ref])

static func allocate() -> Object:
	return Case.new()
