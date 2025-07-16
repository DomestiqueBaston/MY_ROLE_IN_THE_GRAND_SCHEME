class_name Case extends RefCounted

enum Status {
	UNASSIGNED,
	ACTIVE,
	PAUSED,
	DONE
}

var is_layout_needed: bool = true

var npcs: Array[NpcCard]
var evidence: Array[ObjectCard]
var other_objects: Array[ObjectCard]
var locations: Array[LocationCard]

# references to items in locations
var _crime_location: LocationCard
var _player_location: LocationCard

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

# for save/load
var _unique_id: int
static var _max_id: int

func _init():
	_max_id += 1
	_unique_id = _max_id

func _notification(what: int):

	# Cards and Links are Nodes, not RefCounted, so they must be deleted
	# explicitly. But note that Pins are deleted automatically when the Link
	# connecting them is deleted.

	if what == NOTIFICATION_PREDELETE:
		for card_list in [npcs, evidence, other_objects, locations]:
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
	case.print_case()
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
	var total_npc_count = \
		culprit_count + victim_count + accomplice_count + suspect_count + witness_count
	var other_npc_count = 2 * total_npc_count
	total_npc_count += other_npc_count
	var evidence_count = maxi(
		_get_count_from_array(_motive.get("evidence_number", 0)),
		culprit_count + accomplice_count)

	# incriminating links (we don't need to know between whom yet)

	var pre_links: Array[Link.Type]
	var link_types = _motive["link"]
	if link_types.pick_random() != "none":
		for link_type in link_types:
			if link_type == "none":
				continue
			var roll = randi()
			if roll & 1:
				continue
			match link_type:
				"intimacy":
					pre_links.append(Link.Type.INTIMACY)
				"friend":
					pre_links.append(Link.Type.FRIEND)
				"enemy":
					pre_links.append(Link.Type.ENEMY)
				"enemy/friend":
					if roll & 2:
						pre_links.append(Link.Type.FRIEND)
					else:
						pre_links.append(Link.Type.ENEMY)
				"acquaintance":
					pre_links.append(Link.Type.INTIMACY)
				"ideology":
					pre_links.append(Link.Type.IDEOLOGY)
				"debt_influence":
					pre_links.append(Link.Type.DEBT)

	# the difficulty must be determined BEFORE generating the NPCs, because it
	# determines the number of points added to their main characteristics

	var diff = 19.0/50.0 * (1.0
		+ culprit_count
		+ victim_count
		+ accomplice_count * 0.5
		- suspect_count * 0.5
		- witness_count * 0.5
		+ evidence_count
		+ pre_links.size() * 0.5)

	_difficulty = clampi(roundi(diff), 1, 5)

	if _difficulty == 6:
		_duration = 15 + randi_range(-2, 2)
	else:
		_duration = roundi((_difficulty * 4 + 10) * randf_range(0.9, 1.1))

	# NPCs: culprits (if sex is involved, ensure they all have the same sex
	# and orientation to simplify)

	var culprits: Array[NpcCard]
	var culprit_sex = -1
	var culprit_orientation = -1

	if culprit_count > 0:
		var culprit_jobs = _motive.get("culprits_professions", [])
		for i in culprit_count:
			var card = NpcCard.generate_card(
				self, NpcCard.NpcCategory.CULPRIT, culprit_jobs, culprit_sex)
			if culprit_sex >= 0:
				card.orientation = culprit_orientation
			elif Link.Type.INTIMACY in pre_links:
				culprit_sex = card.npc_sex
				culprit_orientation = card.orientation
			culprits.append(card)

	# NPCs: victims (if sex is involved, ensure they are all of the sex that
	# the culprits are interested in)

	var victims: Array[NpcCard]
	var victim_sex
	if culprit_sex < 0:
		victim_sex = -1
	elif culprit_orientation == NpcCard.SexualOrientation.HOMO:
		victim_sex = culprit_sex
	else:
		victim_sex = 1 - culprit_sex

	if victim_count > 0:
		var victim_jobs = _motive.get("victims_professions", [])
		var dead = _motive["dead_victims"]
		for i in victim_count:
			var card = NpcCard.generate_card(
				self, NpcCard.NpcCategory.VICTIM, victim_jobs, victim_sex)
			card.npc_status = NpcCard.NpcStatus.VICTIM
			if dead == "yes":
				card.npc_status = NpcCard.NpcStatus.DEAD
			elif dead == "disappeared":
				card.npc_status = NpcCard.NpcStatus.DISAPPEARED
			elif dead == "random":
				if randi() & 1:
					card.npc_status = NpcCard.NpcStatus.DEAD
			victims.append(card)

	# NPCs: accomplices (if sex is involved, ensure they all have the same
	# sexual interests as the culprits, to simplify)

	var accomplices: Array[NpcCard]

	for i in accomplice_count:
		var card = NpcCard.generate_card(
			self, NpcCard.NpcCategory.ACCOMPLICE, [], culprit_sex)
		if culprit_sex >= 0:
			card.orientation = culprit_orientation
		accomplices.append(card)

	# NPCs: witnesses and suspects

	var witnesses: Array[NpcCard]

	for i in witness_count:
		var card = NpcCard.generate_card(self, NpcCard.NpcCategory.WITNESS)
		card.npc_status = NpcCard.NpcStatus.WITNESS
		witnesses.append(card)

	var suspects: Array[NpcCard]

	for i in suspect_count:
		var card = NpcCard.generate_card(
			self, NpcCard.NpcCategory.SUSPECT, [], culprit_sex)
		card.npc_status = NpcCard.NpcStatus.SUSPECT
		suspects.append(card)

	# other NPCs not involved in the case, and build the array of all NPCs
	# before any calls to _find_partner_for()

	npcs.append_array(culprits)
	npcs.append_array(victims)
	npcs.append_array(accomplices)
	npcs.append_array(witnesses)
	npcs.append_array(suspects)

	for i in other_npc_count:
		npcs.append(NpcCard.generate_card(self))

	# decide which NPCs are couples

	for npc in npcs:

		# NPC has already been coupled to another

		if npc.is_married:
			continue

		# each NPC has 1 chance in 2 of having a partner

		if randi() & 1:
			continue

		var other = _find_partner_for(npc)
		if other:
			npc.is_married = true
			other.is_married = true
			npc.add_connection(Link.Type.INTIMACY, other)
			other.add_connection(Link.Type.INTIMACY, npc)
			other.last_name = npc.last_name

	# assign homes now that we know which NPCs are couples

	for npc in npcs:
		if npc.has_connection(Link.Type.HOME):
			continue

		var home = create_location("LOC001")
		home.add_connection(Link.Type.HOME, npc)
		npc.add_connection(Link.Type.HOME, home)

		var partner = npc.get_one_connection(Link.Type.INTIMACY)
		if partner:
			home.add_connection(Link.Type.HOME, partner)
			partner.add_connection(Link.Type.HOME, home)

	# assign workplaces now that we know where everybody lives

	for npc in npcs:
		var workplace
		if npc.job_location == "LOC001":
			workplace = npc.get_home()
		else:
			workplace = find_or_create_location(npc.job_location)
		npc.add_connection(Link.Type.WORK, workplace)
		workplace.add_connection(Link.Type.WORK, npc)

	# incriminating links between culprits/accomplices and victims

	for link_type in pre_links:
		var npc1
		var roll = randi() % (culprit_count + accomplice_count)
		if roll < culprit_count:
			npc1 = culprits[roll]
		else:
			npc1 = accomplices[roll - culprit_count]
		var npc2 = victims.pick_random()
		npc1.add_connection(link_type, npc2)
		npc2.add_connection(link_type, npc1)

	# make other friend, enemy and acquaintance connections between NPCs, AFTER
	# assigning workplaces, because priority is given to an NPC's colleagues, or
	# his partner's colleagues

	# Note that for NPC #7 (for example), we only look for connections with
	# NPCs #8 and up, because NPCs 0-6 already have all the connections they
	# need. That it why we iterate only to the next-to-last NPC, and why we tell
	# _make_frenemies_for() to look only at NPCs after the given NPC.

	for i in npcs.size() - 1:
		_make_frenemies_for(npcs[i], i+1)

	# assign hangouts, now that we know which NPCs are friends (who share
	# hangouts)

	for npc in npcs:
		var hangout = npc.get_hangout()
		if hangout:
			continue
		hangout = find_hangout()
		var friends: Array[NpcCard]
		_add_friends_of_friends(friends, npc)
		for friend in friends:
			friend.add_connection(Link.Type.HANGOUT, hangout)
			hangout.add_connection(Link.Type.HANGOUT, friend)

	# affairs between NPCs (do this AFTER determining couples)

	for npc in npcs:

		# do nothing if NPC already has an affair

		var partners = npc.get_connections(Link.Type.INTIMACY)
		if partners.size() > 1 or (partners.size() == 1 and not npc.is_married):
			continue

		# otherwise there is a 10% chance NPC is having an affair

		if randi() % 10 == 0:
			var other = _find_partner_for(npc, true)
			if other:
				npc.add_connection(Link.Type.INTIMACY, other)
				other.add_connection(Link.Type.INTIMACY, npc)

	# evidence

	if evidence_count > 0:
		var candidates = _motive.get("evidences", []).duplicate()
		var count = mini(evidence_count, candidates.size() - 1)
		for i in count:
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
			_crime_location = find_or_create_location(actual_location)
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

			# find NPCs associated with the location (home, work, hangout,
			# hideout) to be designated owners of the object

			var location_npcs = card.get_all_npc_connections()
			if npc_owner_count <= location_npcs.size():
				var obj: ObjectCard = ObjectCard.create_card(obj_id)

				if npc_owner_count > 1:
					var candidates = location_npcs.duplicate()
					for i in npc_owner_count:
						var index = randi() % candidates.size()
						var owner = candidates[index]
						obj.add_connection(Link.Type.PROPERTY, owner)
						owner.add_connection(Link.Type.PROPERTY, obj)
						candidates.remove_at(index)
				elif npc_owner_count == 1:
					var owner = location_npcs.pick_random()
					obj.add_connection(Link.Type.PROPERTY, owner)
					owner.add_connection(Link.Type.PROPERTY, obj)

				if location_owner_count > 0:
					obj.add_connection(Link.Type.PROPERTY, card)
					card.add_connection(Link.Type.PROPERTY, obj)

				other_objects.append(obj)
				obj_count -= 1

	# cards and links that are revealed initially

	for npc_list in [victims, witnesses, suspects]:
		for npc in npc_list:
			npc.is_revealed = true
			var home = npc.get_home()
			var work = npc.get_work()
			home.is_revealed = true
			work.is_revealed = true
			_create_link(npc, home, Link.Type.HOME)
			_create_link(npc, work, Link.Type.WORK)

	for victim in victims:
		if victim.is_married:
			var partner = victim.get_one_connection(Link.Type.INTIMACY)
			partner.is_revealed = true
			_create_link(victim, partner, Link.Type.INTIMACY)

	if _crime_location:
		_crime_location.is_revealed = true

func _get_count_from_array(count) -> int:
	if count is Array and not count.is_empty():
		return count.pick_random()
	else:
		return count

func _find_partner_for(npc: NpcCard, married_ok: bool = false) -> NpcCard:
	var start_index = randi() % npcs.size()
	for i in npcs.size():
		var index = (start_index + i) % npcs.size()

		# same NPC?

		if npcs[index] == npc:
			continue
		var other: NpcCard = npcs[index]

		# other NPC already has somebody, or already has a connection to NPC?

		if other.is_known_to(npc):
			continue
		if other.is_married and not married_ok:
			continue

		# sexually compatible?

		if other.orientation != npc.orientation:
			continue
		if npc.orientation == NpcCard.SexualOrientation.HOMO:
			if other.npc_sex != npc.npc_sex:
				continue
		else:
			if other.npc_sex == npc.npc_sex:
				continue

		return other

	return null

#
# Generates friends, enemies and acquaintances for the given NPC, taking them
# first from the NPC's colleagues, and his partner's colleagues.
#
# Only other NPCs with index >= ignore_count are taken into consideration,
# because the NPCs with index < ignore_count have already been allocated all
# the friends, enemies and acquaintances they need.
#
func _make_frenemies_for(npc: NpcCard, ignore_count: int):
	var entourage = []
	_add_to_entourage(entourage, npc, ignore_count)
	for partner in npc.get_connections(Link.Type.INTIMACY):
		_add_to_entourage(entourage, partner, ignore_count)

	var friend_count = npc.get_connections(Link.Type.FRIEND).size()
	var enemy_count = npc.get_connections(Link.Type.ENEMY).size()
	var acquaintance_count = npc.get_connections(Link.Type.ACQUAINTANCE).size()
	var total_count = friend_count + enemy_count + acquaintance_count
	var target_count = [0, 1, 1, 2, 2, 2, 3, 3, 4].pick_random()

	for i in range(total_count, target_count):
		var link_type = [
			Link.Type.FRIEND, Link.Type.ENEMY, Link.Type.ACQUAINTANCE
		].pick_random()
		var frenemy = _find_frenemy_for(npc, entourage, ignore_count)
		if not frenemy:
			return
		npc.add_connection(link_type, frenemy)
		frenemy.add_connection(link_type, npc)

#
# Adds to entourage any NPCs sharing the given NPC's workplace, if
# they are not already in entourage.
#
func _add_to_entourage(entourage, npc: NpcCard, ignore_count: int):
	for location in npc.get_connections(Link.Type.WORK):
		for other in location.get_connections(Link.Type.WORK):
			if not (other.is_known_to(npc) or
					other in entourage or
					npcs.find(other) < ignore_count):
				entourage.append(other)

#
# Finds and returns an NPC who is not already a friend, enemy or acquaintance of
# the given NPC. If the candidates array is not empty, an NPC is taken from
# there at random, and then removed from candidates; otherwise, an NPC (whose
# index >= ignore_count) is picked at random. Returns null if no eligible NPC is
# found.
#
func _find_frenemy_for(npc: NpcCard, candidates, ignore_count) -> NpcCard:
	if not candidates.is_empty():
		var which = randi() % candidates.size()
		var other = candidates[which]
		candidates.remove_at(which)
		return other

	var index = randi_range(ignore_count, npcs.size() - 1)
	for i in npcs.size() - ignore_count:
		var other = npcs[index]
		if not (other == npc or
				other in npc.get_connections(Link.Type.FRIEND) or
				other in npc.get_connections(Link.Type.ENEMY) or
				other in npc.get_connections(Link.Type.ACQUAINTANCE)):
			return other
		index += 1
		if index == npcs.size():
			index = ignore_count

	return null

#
# Returns an array containing the given npc, his friends, all their friends, and
# so on.
#
func _add_friends_of_friends(friends: Array[NpcCard], npc: NpcCard):
	if not friends.has(npc):
		friends.append(npc)
		for ff in npc.get_connections(Link.Type.FRIEND):
			_add_friends_of_friends(friends, ff)

func _create_link(from: BaseCard, to: BaseCard, type: Link.Type) -> Link:
	var pin1 = Pin.allocate()
	pin1.card_location = from.find_closest_unused_pin(Vector2(BaseCard.size.x, 0))
	pin1.card = from

	var pin2 = Pin.allocate()
	pin2.card_location = to.find_closest_unused_pin(Vector2(0, 0))
	pin2.card = to

	var link = Link.allocate()
	link.type = type
	link.pin1 = pin1
	link.pin2 = pin2

	add_link(link)
	return link

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

func get_player_location() -> LocationCard:
	return _player_location

##
## Returns all the cards created for the case, including NPCs, objects and
## locations.
##
func get_all_cards() -> Array[BaseCard]:
	var all_cards: Array[BaseCard]
	for card_list in [npcs, evidence, other_objects, locations]:
		all_cards.append_array(card_list)
	return all_cards

##
## Returns an array of the cards that have been revealed to the player thus far.
##
func get_revealed_cards() -> Array[BaseCard]:
	var cards: Array[BaseCard]
	for card_list in [npcs, evidence, other_objects, locations]:
		for card in card_list:
			if card.is_revealed:
				cards.append(card)
	return cards

##
## Returns the cards for all the NPCs created for the case.
##
func get_all_npcs() -> Array[NpcCard]:
	return npcs

func add_link(link: Link):
	_links.append(link)

func remove_link(link: Link):
	_links.erase(link)

func get_links() -> Array[Link]:
	return _links

##
## Looks for an existing location with the given ID, or creates a new one if
## none is found.
##
func find_or_create_location(location_id: String) -> LocationCard:
	for card in locations:
		if card.database_id == location_id:
			return card
	return create_location(location_id)

##
## Creates a new location card from the given ID in the location database.
##
func create_location(location_id: String) -> LocationCard:
	var card = LocationCard.create_card(location_id)
	locations.append(card)
	return card

##
## Finds or creates a random hangout location.
##
func find_hangout() -> LocationCard:
	var hangouts = []
	for loc in _location_data:
		if "yes" in _location_data[loc].get("hangout", []):
			hangouts.append(loc)
	return find_or_create_location(hangouts.pick_random())

##
## Creates a random hideout location.
##
func create_hideout() -> LocationCard:
	var hideouts = []
	for loc in _location_data:
		if "secret" in _location_data[loc].get("hangout", []):
			hideouts.append(loc)
	return create_location(hideouts.pick_random())

func start():
	_status = Status.ACTIVE

func pause():
	_status = Status.PAUSED

func print_case():
	print()
	print("************************************************************")
	print("case ", _case_name)
	print("************************************************************")
	for npc in npcs:
		print()
		npc.print_npc()

#
# For save/load.
#
func get_custom_class():
	return SaveLoadTools.Class.CASE

#
# For save/load.
#
func get_unique_id():
	return "case%d" % _unique_id

#
# For save/load.
#
func get_referenced_objects():
	var refs = []
	refs.append_array(npcs)
	refs.append_array(evidence)
	refs.append_array(other_objects)
	refs.append_array(locations)
	refs.append_array(_links)
	return refs

#
# For save/load.
#
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

	if npcs:
		var npc_refs = []
		for npc in npcs:
			npc_refs.append(npc.get_unique_id())
		dict["npcs"] = npc_refs

	if evidence:
		var evidence_refs = []
		for card in evidence:
			evidence_refs.append(card.get_unique_id())
		dict["evidence"] = evidence_refs

	if other_objects:
		var object_refs = []
		for card in other_objects:
			object_refs.append(card.get_unique_id())
		dict["other_objects"] = object_refs

	if locations:
		var location_refs = []
		for card in locations:
			location_refs.append(card.get_unique_id())
		dict["locations"] = location_refs

	if _crime_location:
		dict["crime_location"] = _crime_location.get_unique_id()

	if _player_location:
		dict["player_location"] = _player_location.get_unique_id()

	if _links:
		var link_refs = []
		for link in _links:
			link_refs.append(link.get_unique_id())
		dict["links"] = link_refs

	return dict

#
# For save/load.
#
func restore(dict, catalog):
	_case_id = dict.get("case_id", "")
	_case_name = dict.case_name
	_crime = dict.crime
	_motive = dict.motive
	_difficulty = dict.difficulty
	_duration = dict.duration
	_status = dict.status
	is_layout_needed = dict.get("is_layout_needed", true)
	for ref in dict.get("npcs", []):
		npcs.append(catalog[ref])
	for ref in dict.get("evidence", []):
		evidence.append(catalog[ref])
	for ref in dict.get("other_objects", []):
		other_objects.append(catalog[ref])
	for ref in dict.get("locations", []):
		locations.append(catalog[ref])
	if "crime_location" in dict:
		_crime_location = catalog[dict.crime_location]
	if "player_location" in dict:
		_player_location = catalog[dict.player_location]
	for ref in dict.get("links", []):
		_links.append(catalog[ref])

#
# For save/load.
#
static func allocate() -> Object:
	return Case.new()
