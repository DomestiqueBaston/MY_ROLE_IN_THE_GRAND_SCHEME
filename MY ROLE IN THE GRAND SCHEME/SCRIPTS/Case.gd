class_name Case extends RefCounted

enum Status {
	UNASSIGNED,
	ACTIVE,
	PAUSED,
	DONE
}

var is_layout_needed: bool = true

var culprits: Array[NpcCard]
var victims: Array[NpcCard]
var witnesses: Array[NpcCard]
var accomplices: Array[NpcCard]
var suspects: Array[NpcCard]
var other_npcs: Array[NpcCard]
var evidence: Array[ObjectCard]
var other_objects: Array[ObjectCard]
var locations: Array[LocationCard]

var _crime_location: LocationCard  # reference to an item in locations

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
var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data

func _notification(what: int):

	# Cards and Links are Nodes, not RefCounted, so they must be deleted
	# explicitly. But note that Pins are deleted automatically when the Link
	# connecting them is deleted.

	if what == NOTIFICATION_PREDELETE:
		for card_list in [
				culprits, victims, witnesses, accomplices, suspects, other_npcs,
				evidence, other_objects, locations
		]:
			for card in card_list:
				card.queue_free()
			card_list.clear()

		_crime_location = null

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
					self, NpcCard.NpcCategory.CULPRIT, culprit_jobs))

	# NPCs: victims

	if victim_count > 0:
		var victim_jobs = _motive.get("victims_professions", [])
		var dead = _motive["dead_victims"]
		for i in victim_count:
			var card = NpcCard.generate_card(
				self, NpcCard.NpcCategory.VICTIM, victim_jobs)
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
		var card = NpcCard.generate_card(self, NpcCard.NpcCategory.WITNESS)
		card.npc_status = NpcCard.NpcStatus.WITNESS
		witnesses.append(card)

	for i in accomplice_count:
		accomplices.append(
			NpcCard.generate_card(self, NpcCard.NpcCategory.ACCOMPLICE))

	for i in suspect_count:
		var card = NpcCard.generate_card(self, NpcCard.NpcCategory.SUSPECT)
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
		other_npcs.append(NpcCard.generate_card(self, NpcCard.NpcCategory.USELESS))

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

	var actual_location: String

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

	var location_card: LocationCard

	match actual_location:
		"none":
			location_card = null
		"home":
			location_card = victims[0].get_home()
		"work":
			location_card = victims[0].get_work()
		"culprit_home":
			location_card = culprits[0].get_home()
		"culprit_work":
			location_card = culprits[0].get_work()
		_:
			_crime_location = find_or_create_location(
				actual_location, get_all_npcs().pick_random())
			location_card = _crime_location

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

	# populate all locations with useless objects

	for card: LocationCard in locations:
		var obj_count = randi_range(0, 3)
		while obj_count > 0:
			var obj_id = _object_data.keys().pick_random()
			var owners = _object_data[obj_id].get("owners", {})
			var npc_owners = owners.get("npc", [0])
			var npc_owner_count = npc_owners.pick_random() as int
			var location_owners = owners.get("location", [0])
			var location_owner_count = location_owners.pick_random() as int
			if npc_owner_count <= card.get_npc_count():
				var obj: ObjectCard = ObjectCard.create_card(obj_id)
				if npc_owner_count > 1:
					var candidates = card.get_npcs().duplicate()
					for i in npc_owner_count:
						var index = randi() % candidates.size()
						obj.add_object_owner(candidates[index])
						candidates.remove_at(index)
				elif npc_owner_count == 1:
					obj.add_object_owner(card.get_npcs().pick_random())
				if location_owner_count > 0:
					obj.add_object_owner(card)
				other_objects.append(obj)
				obj_count -= 1

	# TODO: friends/enemies/acquaintances/couples

	# cards and links that are revealed initially

	for npc_list in [victims, witnesses, suspects]:
		for npc in npc_list:
			npc.is_revealed = true
			var home = npc.get_home()
			var work = npc.get_work()
			home.is_revealed = true
			work.is_revealed = true

			var pin1 = Pin.allocate()
			pin1.card_location = Pin.Location.TOP_RIGHT
			pin1.card = npc

			var pin2 = Pin.allocate()
			pin2.card_location = home.find_closest_unused_pin(Vector2(0, 0))
			pin2.card = home

			var link1 = Link.allocate()
			link1.type = Link.Type.HOME
			link1.status = Link.Status.CONFIRMED
			link1.pin1 = pin1
			link1.pin2 = pin2

			pin1 = Pin.allocate()
			pin1.card_location = Pin.Location.RIGHT_CENTER
			pin1.card = npc

			pin2 = Pin.allocate()
			pin2.card_location = work.find_closest_unused_pin(Vector2(0, 0))
			pin2.card = work

			var link2 = Link.allocate()
			link2.type = Link.Type.WORK
			link2.status = Link.Status.CONFIRMED
			link2.pin1 = pin1
			link2.pin2 = pin2

			add_link(link1)
			add_link(link2)

	if _crime_location:
		_crime_location.is_revealed = true

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

func get_crime_location() -> LocationCard:
	return _crime_location

##
## Returns all the cards created for the case, including NPCs, objects and
## locations.
##
func get_all_cards() -> Array[BaseCard]:
	var all_cards: Array[BaseCard]
	for card_list in [
		culprits, victims, witnesses, accomplices, suspects, other_npcs,
		evidence, other_objects, locations
	]:
		all_cards.append_array(card_list)
	return all_cards

##
## Returns an array of the cards that have been revealed to the player thus far.
##
func get_revealed_cards() -> Array[BaseCard]:
	var cards: Array[BaseCard]
	for card_list in [
		culprits, victims, witnesses, accomplices, suspects, other_npcs,
		evidence, other_objects, locations
	]:
		for card in card_list:
			if card.is_revealed:
				cards.append(card)
	return cards

##
## Returns the cards for all the NPCs created for the case.
##
func get_all_npcs() -> Array[NpcCard]:
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

##
## Looks for an existing location with the given ID, or creates a new one if
## none is found. In either case, the given NPC is associated with the location.
##
func find_or_create_location(location_id: String, npc: NpcCard) -> LocationCard:
	for card in locations:
		if card.database_id == location_id:
			card.add_npc(npc)
			return card
	return create_location(location_id, npc)

##
## Creates a new location card from the given ID in the location database. The
## given NPC is associated with the location.
##
func create_location(location_id: String, npc: NpcCard) -> LocationCard:
	var card = LocationCard.create_card(location_id)
	if npc:
		card.add_npc(npc)
	locations.append(card)

	# populate the new location with some number of useless objects

	#var obj_count = randi_range(0, 3)
	#while obj_count > 0:
		#var obj_id = _object_data.keys().pick_random()
		#var owners = _object_data[obj_id].get("owners", {})
		#var npc_owners = owners.get("npc", [0])
		#var location_owners = owners.get("location", [0])
		#if (1 in npc_owners or 1.0 in npc_owners) and \
			#(0 in location_owners or 0.0 in location_owners):
			#var obj = ObjectCard.create_card(obj_id)
			#obj.add_object_owner(npc)
			#other_objects.append(obj)
			#obj_count -= 1

	return card

##
## Finds or creates a random hangout location and associates the given NPC with
## it.
##
func find_hangout(npc: NpcCard) -> LocationCard:
	var hangouts = []
	for loc in _location_data:
		if "yes" in _location_data[loc].get("hangout", []):
			hangouts.append(loc)
	return find_or_create_location(hangouts.pick_random(), npc)

##
## Creates a random hideout location and associates the given NPC with it.
##
func create_hideout(npc: NpcCard) -> LocationCard:
	var hideouts = []
	for loc in _location_data:
		if "secret" in _location_data[loc].get("hangout", []):
			hideouts.append(loc)
	return create_location(hideouts.pick_random(), npc)

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
	refs.append_array(other_objects)
	refs.append_array(locations)
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
		"status": _status,
		"is_layout_needed": is_layout_needed
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

	if other_objects:
		var object_refs = []
		for card in other_objects:
			object_refs.append(SaveLoadTools.get_object_id(card))
		dict["other_objects"] = object_refs

	if locations:
		var location_refs = []
		for card in locations:
			location_refs.append(SaveLoadTools.get_object_id(card))
		dict["locations"] = location_refs

	if _crime_location:
		dict["crime_location"] = SaveLoadTools.get_object_id(_crime_location)

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
	is_layout_needed = dict.get("is_layout_needed", true)
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
	for ref in dict.get("other_objects", []):
		other_objects.append(catalog[ref])
	for ref in dict.get("locations", []):
		locations.append(catalog[ref])
	if "crime_location" in dict:
		_crime_location = catalog[dict.crime_location]
	for ref in dict.get("links", []):
		_links.append(catalog[ref])

static func allocate() -> Object:
	return Case.new()
