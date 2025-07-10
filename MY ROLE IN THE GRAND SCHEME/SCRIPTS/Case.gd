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
var locations: Array[LocationCard]
var crime_location: LocationCard  # reference to a locations item

var _case_id: String
var _case_name: String
var _crime: String
var _motive: Dictionary
var _difficulty: int
var _duration: int
var _status: Status = Status.UNASSIGNED
var _links: Array[Link]

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data
var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data

func _notification(what: int):

	# Cards and Links are Nodes, not RefCounted, so they must be deleted
	# explicitly. But note that Pins are deleted automatically when the Link
	# connecting them is deleted.

	if what == NOTIFICATION_PREDELETE:
		for card_list in [
				culprits, victims, witnesses, accomplices, suspects, other_npcs,
				evidence, locations
		]:
			for card in card_list:
				card.queue_free()
			card_list.clear()

		crime_location = null

		for link in _links:
			link.queue_free()
		_links.clear()

static func generate() -> Case:
	var case = Case.new()
	case._randomize()
	return case

#
# Note that it is assumed, for now, that the Case is brand new. Otherwise we
# would need to clear everything first.
#
func _randomize():
	_case_id = _generate_case_id()

	# crime, motive and lots of other information about the case

	_crime = GameState.get_new_crime()
	_motive = _crime_data[_crime].pick_random()
	_case_name = _motive["name"]

	var culprit_count = _get_count_from_array(_motive.get("culprits", 0))
	var victim_count = _get_count_from_array(_motive.get("victims", 0))
	var witness_count = _get_count_from_array(_motive.get("witnesses", 0))
	var accomplice_count = _get_count_from_array(_motive.get("accomplices", 0))
	var suspect_count = _get_count_from_array(_motive.get("suspects", 0))
	var evidence_count = maxi(
		_get_count_from_array(_motive.get("evidence_number", 0)),
		culprit_count)

	# the difficulty must be determined BEFORE generating the NPCs, because it
	# determine the number of points added to their main characteristics

	# TODO: difficulty += number of links * 0.5

	var diff = 19.0/50.0 * (1.0
		+ culprit_count
		+ victim_count
		+ accomplice_count * 0.5
		- suspect_count * 0.5
		- witness_count * 0.5
		+ evidence_count)

	_difficulty = clampi(roundi(diff), 1, 5)

	if _difficulty == 6:
		_duration = 15 + randi_range(-2, 2)
	else:
		_duration = roundi((_difficulty * 4 + 10) * randf_range(0.9, 1.1))

	# NPCs: culprits

	if culprit_count > 0:
		var culprit_jobs = _motive.get("culprits_professions", [])
		for i in culprit_count:
			culprits.append(
				NpcCard.generate_card(
					self, NpcCard.Category.NORMAL, culprit_jobs))

	# NPCs: victims

	if victim_count > 0:
		var victim_jobs = _motive.get("victims_professions", [])
		var dead = _motive["dead_victims"]
		for i in victim_count:
			var card = NpcCard.generate_card(
				self, NpcCard.Category.NORMAL, victim_jobs)
			card.npc_status = NpcCard.NpcStatus.VICTIM
			if dead == "yes":
				card.npc_status = NpcCard.NpcStatus.DEAD
			elif dead == "disappeared":
				card.npc_status = NpcCard.NpcStatus.DISAPPEARED
			elif dead == "random":
				if randi() & 1:
					card.npc_status = NpcCard.NpcStatus.DEAD
			victims.append(card)

	# NPCs: witnesses, accomplices, suspects

	for i in witness_count:
		var card = NpcCard.generate_card(self)
		card.npc_status = NpcCard.NpcStatus.WITNESS
		witnesses.append(card)

	for i in accomplice_count:
		accomplices.append(NpcCard.generate_card(self))

	for i in suspect_count:
		var card = NpcCard.generate_card(self)
		card.npc_status = NpcCard.NpcStatus.SUSPECT
		suspects.append(card)

	# NPCs unrelated to the case

	var useless_count = 0

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

	for i in useless_count:
		other_npcs.append(NpcCard.generate_card(self, NpcCard.Category.USELESS))

	# evidence

	if evidence_count > 0:
		var candidates = _motive.get("evidences", []).duplicate()
		# this should never be necessary
		evidence_count = mini(evidence_count, candidates.size() - 1)
		for i in evidence_count:
			var which = randi() % candidates.size()
			var card = ObjectCard.create_card(candidates[which])
			# TODO: set location and owner?
			candidates.remove_at(which)
			evidence.append(card)

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

	# TODO: use and update locations array...

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
		crime_location = find_or_create_location(actual_location)
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

	# TODO: friends/enemies/couples??
	# TODO: links
	# TODO: useless objects

func _get_count_from_array(count) -> int:
	if count is Array and not count.is_empty():
		return count.pick_random()
	else:
		return count

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

##
## Returns all the cards created for the case, including NPCs, objects and
## locations.
##
func get_cards() -> Array[BaseCard]:
	var all_cards: Array[BaseCard]
	for card_list in [
		culprits, victims, witnesses, accomplices, suspects, other_npcs,
		evidence, locations
	]:
		all_cards.append_array(card_list)
	return all_cards

##
## Returns the cards for all the NPCs created for the case.
##
func get_npcs() -> Array[NpcCard]:
	var all_npcs: Array[NpcCard]
	for card_list in [
		culprits, victims, witnesses, accomplices, suspects, other_npcs
	]:
		all_npcs.append_array(card_list)
	return all_npcs

func add_link(link: Link):
	_links.append(link)

func remove_link(link: Link):
	_links.erase(link)

func get_links() -> Array[Link]:
	return _links

func find_or_create_location(location_id: String) -> LocationCard:
	for card in locations:
		if card.database_id == location_id:
			return card
	return create_location(location_id)

func create_location(location_id: String) -> LocationCard:
	var card = LocationCard.create_card(location_id)
	locations.append(card)
	return card

func find_hangout() -> LocationCard:
	var hangouts = []
	for loc in _location_data:
		if "yes" in _location_data[loc].get("hangout", []):
			hangouts.append(loc)
	return find_or_create_location(hangouts.pick_random())

func find_hideout() -> LocationCard:
	var hideouts = []
	for loc in _location_data:
		if "secret" in _location_data[loc].get("hangout", []):
			hideouts.append(loc)
	return create_location(hideouts.pick_random())

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
