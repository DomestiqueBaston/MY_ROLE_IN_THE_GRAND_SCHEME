class_name Case extends RefCounted

enum Status {
	UNASSIGNED,
	ACTIVE,
	PAUSED,
	DONE
}

enum SolutionResult {
	WRONG,
	HALF_RIGHT,
	RIGHT
}

var is_layout_needed: bool = true

## All NPCs in the case except for minions.
var npcs: Array[NpcCard]

## All objects in the case that are evidence.
var evidence: Array[ObjectCard]

## Other objects in the case (not evidence).
var other_objects: Array[ObjectCard]

## All locations in the case.
var locations: Array[LocationCard]

## The crime category that has been selected by the player in the motive list.
var selected_crime: String

## The ID of the motive that has been selected by the player in the motive list.
var selected_motive: String

# references to items in locations
var _crime_locations: Array[LocationCard]

var _case_id: String
var _case_random_name: String
var _case_name: String
var _crime: String
var _motive: Dictionary
var _victim_count: int
var _dead_victim_count: int
var _culprit_count: int
var _accomplice_count: int
var _difficulty: int
var _duration: int
var _status: Status = Status.UNASSIGNED
var _start_day: int = -1
var _links: Array[Link]

# date/time when a minion is scheduled to attack the player
var _next_minion_attack: int = -1

# minion attacking the player
var _minion: NpcCard

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data
var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data
var _case_name_data = preload("res://JSON/CASE/Random_Case_Names.json").data

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

		if _minion:
			_minion.queue_free()
			_minion = null

		_crime_locations.clear()

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
	_case_random_name = _generate_random_name()

	# crime, motive and lots of other information about the case

	_crime = GameState.get_new_crime()
	var crime_dict = _crime_data[_crime]
	var motive_id = crime_dict.keys().pick_random()
	_motive = crime_dict[motive_id]
	_case_name = _motive["name"]

	_victim_count = _get_count_from_array(_motive.get("victims", 0))
	_culprit_count = _get_count_from_array(_motive.get("culprits", 0))
	_accomplice_count = _get_count_from_array(_motive.get("accomplices", 0))
	var witness_count = _get_count_from_array(_motive.get("witnesses", 0))
	var suspect_count = _get_count_from_array(_motive.get("suspects", 0))
	var total_npc_count = \
		_culprit_count + _victim_count + _accomplice_count + suspect_count + witness_count
	var other_npc_count = 2 * total_npc_count
	total_npc_count += other_npc_count
	var evidence_count = maxi(
		_get_count_from_array(_motive.get("evidence_number", 0)),
		_culprit_count + _accomplice_count + _victim_count)

	# determine victim statuses now, because we need to know if the player can
	# talk to them or not

	var victim_status: Array[NpcCard.NpcStatus]
	var dead_victims = _motive["dead_victims"]

	for i in _victim_count:
		if dead_victims == "yes":
			victim_status.append(NpcCard.NpcStatus.DEAD)
		elif dead_victims == "disappeared":
			victim_status.append(NpcCard.NpcStatus.DISAPPEARED)
		elif dead_victims == "random":
			if randi() & 1 == 0:
				victim_status.append(NpcCard.NpcStatus.DEAD)
			else:
				victim_status.append(NpcCard.NpcStatus.NONE)
		else:
			victim_status.append(NpcCard.NpcStatus.NONE)
		if victim_status.back() != NpcCard.NpcStatus.NONE:
			_dead_victim_count += 1

	# incriminating links (we don't need to know between whom yet)

	var pre_links: Array[Link.Type]
	var link_types = _motive["link"]
	var is_adultery = _motive.get("is_adultery", false)
	if _dead_victim_count > 0 or link_types.pick_random() != "none":
		for link_type in link_types:
			if link_type == "none":
				continue

			# there is a 50% chance that each link will be created, but with
			# one special case: ALL links are created if the victims are dead
			# or disappeared (so the player will not be able to talk to them)

			if _dead_victim_count > 0 or (randi() & 1):
				match link_type:
					"intimacy":
						pre_links.append(Link.Type.INTIMACY)
					"friend":
						pre_links.append(Link.Type.FRIEND)
					"enemy":
						pre_links.append(Link.Type.ENEMY)
					"enemy/friend":
						if randi() & 1:
							pre_links.append(Link.Type.FRIEND)
						else:
							pre_links.append(Link.Type.ENEMY)
					"acquaintance":
						pre_links.append(Link.Type.ACQUAINTANCE)
					"ideology":
						pre_links.append(Link.Type.IDEOLOGY)
					"debt_influence":
						pre_links.append(Link.Type.DEBT)
					"any":
						pre_links.append(Link.incriminating_types.pick_random())

	# the difficulty must be determined BEFORE generating the NPCs, because it
	# determines the number of points added to their main characteristics

	var diff = (1
		+ _victim_count + _culprit_count + _accomplice_count + evidence_count
		- 4) * 0.5

	_difficulty = clampi(roundi(diff), 1, 5)

	if _difficulty == 6:
		_duration = 15 + randi_range(-2, 2)
	else:
		_duration = roundi((_difficulty * 2 + 10) * randf_range(0.9, 1.1))

	# NPCs: culprits (if sex is involved, ensure they all have the same sex
	# and orientation to simplify)

	var culprits: Array[NpcCard]
	var culprit_sex = -1
	var culprit_orientation = -1

	if _culprit_count > 0:
		var culprit_jobs = _motive.get("culprits_professions", [])
		for i in _culprit_count:
			var card = NpcCard.generate_card(
				self, NpcCard.NpcRole.CULPRIT, culprit_jobs, culprit_sex)
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

	var victim_jobs
	if "same_professions" in _motive.get("flags", []):
		victim_jobs = [culprits[0].job]
	else:
		victim_jobs = _motive.get("victims_professions", [])

	for i in _victim_count:
		var card = NpcCard.generate_card(
			self, NpcCard.NpcRole.VICTIM, victim_jobs, victim_sex)
		card.apparent_role = NpcCard.NpcRole.VICTIM
		card.npc_status = victim_status[i]
		victims.append(card)

	# NPCs: accomplices (if sex is involved, ensure they all have the same
	# sexual interests as the culprits, to simplify, except in adultery cases,
	# where they have the same sex as the victim)

	var accomplices: Array[NpcCard]
	var accomplice_sex = victim_sex if is_adultery else culprit_sex

	for i in _accomplice_count:
		var card = NpcCard.generate_card(
			self, NpcCard.NpcRole.ACCOMPLICE, [], accomplice_sex)
		if not is_adultery and culprit_sex >= 0:
			card.orientation = culprit_orientation
		accomplices.append(card)

	# NPCs: witnesses and suspects

	var witnesses: Array[NpcCard]

	for i in witness_count:
		var card = NpcCard.generate_card(self, NpcCard.NpcRole.WITNESS)
		card.apparent_role = NpcCard.NpcRole.WITNESS
		witnesses.append(card)

	var suspects: Array[NpcCard]

	for i in suspect_count:
		var card = NpcCard.generate_card(
			self, NpcCard.NpcRole.SUSPECT, [], culprit_sex)
		card.apparent_role = NpcCard.NpcRole.SUSPECT
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

	# in cases of adultery, the victim is always married to the culprit, and
	# there is always an intimacy link between the culprit and an accomplice

	if is_adultery and victims and culprits:
		var victim = victims.front()
		var culprit = culprits.front()
		victim.is_married = true
		culprit.is_married = true
		Card.add_bidirectional_connection(Link.Type.SPOUSE, victim, culprit)
		victim.last_name = culprit.last_name
		if accomplices:
			Card.add_bidirectional_connection(
				Link.Type.INTIMACY, culprit, accomplices.front())

	# decide which NPCs are couples: each has a 50% chance of being in a couple

	# Note that for NPC #7 (for example), we only look for partners among NPCs
	# #8 and up, because we have already "rolled the dice" for NPCs 0-6. That is
	# why we iterate only as far as the next-to-last NPC here, and is why we
	# tell _find_partner_for() to look only at NPCs that follow the current NPC
	# in the list. This same pattern is repeated below whenever we create
	# connections between pairs of NPCs with a probability of less than 100%.


	for i in npcs.size() - 1:
		var npc = npcs[i]
		if not npc.is_married and randi() & 1:
			var other = _find_partner_for(npc, i, false)
			if other:
				npc.is_married = true
				other.is_married = true
				Card.add_bidirectional_connection(Link.Type.SPOUSE, npc, other)
				other.last_name = npc.last_name

	# assign homes now that we know which NPCs are couples

	for npc in npcs:
		if npc.has_connection(Link.Type.HOME):
			continue

		var home = _create_location("LOC001")
		Card.add_bidirectional_connection(Link.Type.HOME, home, npc)

		var partner = npc.get_one_connection(Link.Type.SPOUSE)
		if partner:
			Card.add_bidirectional_connection(Link.Type.HOME, home, partner)

	# assign workplaces now that we know where everybody lives

	for npc in npcs:
		var workplace
		if npc.job_location == "LOC001":
			workplace = npc.get_home()
		else:
			workplace = _find_or_create_location(npc.job_location)
		Card.add_bidirectional_connection(Link.Type.WORK, npc, workplace)

	# incriminating links between culprits/accomplices and victims; dead or
	# disappeared victims have priority when creating links, since the player
	# will not be able to talk to them

	if _victim_count > 0:
		var victim_index = 0
		if _dead_victim_count > 0:
			while (victim_index < _victim_count
				   and victim_status[victim_index] == NpcCard.NpcStatus.NONE):
				victim_index += 1
		for link_type in pre_links:
			var npc1
			var roll = randi() % (_culprit_count + _accomplice_count)
			if roll < _culprit_count:
				npc1 = culprits[roll]
			else:
				npc1 = accomplices[roll - _culprit_count]
			var npc2 = victims[victim_index]
			Card.add_bidirectional_connection(link_type, npc1, npc2)
			victim_index = (victim_index + 1) % _victim_count

	# make other friend, enemy and acquaintance connections between NPCs, AFTER
	# assigning workplaces, because priority is given to an NPC's colleagues, or
	# his partner's colleagues

	for i in npcs.size() - 1:
		_make_frenemies_for(npcs[i], i+1)

	# assign hangouts, now that we know which NPCs are friends (who share
	# hangouts), and hideouts

	for npc in npcs:
		var hangout = npc.get_hangout()

		# one hangout is shared by the NPC, his friends, their friends, etc.
		if hangout == null:
			hangout = _find_hangout_or_hideout(false)
			var friends: Array[NpcCard]
			_add_friends_of_friends(friends, npc)
			for friend in friends:
				Card.add_bidirectional_connection(Link.Type.HANGOUT, friend, hangout)

		# 1 in 4 NPCs has a second hangout of his own
		if randi() % 4 == 0:
			var hangout2 = null
			while hangout2 == null or hangout2 == hangout:
				hangout2 = _find_hangout_or_hideout(false)
			Card.add_bidirectional_connection(Link.Type.HANGOUT, npc, hangout2)

		# not all NPCs have a hideout
		var hideout_probability
		if npc.actual_role in [NpcCard.NpcRole.CULPRIT, NpcCard.NpcRole.ACCOMPLICE]:
			hideout_probability = 0.8
		else:
			hideout_probability = 0.4
		if randf() < hideout_probability:
			var hideout = _find_hangout_or_hideout(true)
			Card.add_bidirectional_connection(Link.Type.HIDEOUT, npc, hideout)

	# affairs between NPCs (do this AFTER determining couples)

	for i in npcs.size() - 1:
		var npc = npcs[i]

		# do nothing if NPC already has an affair

		if npc.get_one_connection(Link.Type.INTIMACY):
			continue

		# otherwise there is a 10% chance NPC is having an affair

		if randi() % 10 == 0:
			var other = _find_partner_for(npc, i, true)
			if other:
				Card.add_bidirectional_connection(Link.Type.INTIMACY, npc, other)

	# debt/influence and ideology links between NPCs

	for i in npcs.size() - 1:
		var roll = randi() % 10
		if roll < 3:
			var npc = npcs[i]
			if roll != 0:
				_create_new_connection(npc, Link.Type.DEBT, i)
			if roll != 1:
				_create_new_connection(npc, Link.Type.IDEOLOGY, i)

	# determine crime locations BEFORE distributing evidence

	var crime_location_count
	if "crime_location_count" in _motive:
		crime_location_count = _get_count_from_array(_motive.crime_location_count)
	else:
		crime_location_count = 0  # actually: 0 or 1

	var secret_locations: Array[LocationCard]
	var location_name = _motive["crime_location"]

	# if there are multiple crime locations, we assume that all candidates are
	# real location IDs, not "none", "any", etc., and each dead victim is placed
	# in one of those locations

	if (crime_location_count > 1
		and location_name is Array
		and location_name.size() >= crime_location_count):

		# pick locations at random from the given list

		var victim_count_per_location: Array[int]

		for i in crime_location_count:
			var index = randi() % location_name.size()
			var id = location_name[index]
			location_name.remove_at(index)
			secret_locations.append(_find_or_create_location(id))
			_reveal_crime_scene_maybe(
				secret_locations.back(), _motive.get("known_crime_location", 1))
			victim_count_per_location.append(0)

		# distribute dead victims among the crime scenes

		var location_candidates: Array[LocationCard] = secret_locations.duplicate()
		var max_per_location: int = _motive.get("max_victims_per_location", 100)

		for victim in victims:
			if victim.npc_status == NpcCard.NpcStatus.DEAD:
				var index = randi() % location_candidates.size()
				var location: LocationCard = location_candidates[index]
				Card.add_bidirectional_connection(Link.Type.FOUND, victim, location)
				victim_count_per_location[index] += 1
				if victim_count_per_location[index] >= max_per_location:
					location_candidates.remove_at(index)

	else:
		if location_name is Array and not location_name.is_empty():
			location_name = location_name.pick_random()

		var secret_location: LocationCard

		match location_name:
			"none":
				secret_location = null
			"any":
				var who = (culprits if randi() & 1 else victims).pick_random()
				secret_location = who.get_all_location_connections().pick_random()
			"any_culprit":
				var who = culprits.pick_random()
				secret_location = who.get_all_location_connections().pick_random()
			"any_victim":
				var who = victims.pick_random()
				secret_location = who.get_all_location_connections().pick_random()
			"home":
				secret_location = victims.pick_random().get_home()
			"work":
				secret_location = victims.pick_random().get_work()
			"culprit_home":
				secret_location = culprits.pick_random().get_home()
			"culprit_work":
				secret_location = culprits.pick_random().get_work()
			_:
				secret_location = _find_or_create_location(location_name)

		if secret_location:
			secret_locations.append(secret_location)
			_reveal_crime_scene_maybe(
				secret_location, _motive.get("known_crime_location", 1))

	# evidence

	if evidence_count > 0:
		# which objects to instantiate for evidence
		var candidates = _motive.get("evidences", []).duplicate()

		# which NPCs the objects belong to
		var bad_guys = culprits + accomplices
		var all_owners = bad_guys + victims

		# some NPCs may get more than one piece of evidence, if there are more

		if all_owners.size() < evidence_count:
			var more_owners = []
			for i in range(all_owners.size(), evidence_count):
				more_owners.append(all_owners.pick_random())
			all_owners.append_array(more_owners)

		# create a card for each piece of evidence and assign it to an NPC (or
		# possibly several NPCs) and an appropriate location

		for i in mini(evidence_count, candidates.size()):

			# choose an object ID at random from the given candidates, and look
			# up in the database how many owners it has (NPCs and locations) (we
			# impose a maximum of 2 NPC owners and 1 location owner here)

			var obj_id = candidates.pop_at(randi() % candidates.size())
			var obj = ObjectCard.create_card(obj_id)

			var owner_counts = _get_object_owner_counts(obj_id)
			var npc_owner_count = owner_counts[0]
			var location_owner_count = owner_counts[1]

			# choose an appropriate location, depending on the object's owners,
			# and create all the appropriate PROPERTY and FOUND connections

			var npc = all_owners[i]
			Card.add_bidirectional_connection(Link.Type.PROPERTY, obj, npc)

			var location: LocationCard

			if npc_owner_count > 1:
				var other_owner
				if npc.actual_role == NpcCard.NpcRole.VICTIM:
					other_owner = bad_guys.pick_random()
				else:
					other_owner = victims.pick_random()

				Card.add_bidirectional_connection(Link.Type.PROPERTY, obj, other_owner)

				match randi() % (3 if secret_locations else 2):
					0:
						location = locations.pick_random()
					1:
						location = npc.get_all_location_connections().pick_random()
					2:
						location = secret_locations.pick_random()
			else:
				if npc.actual_role == NpcCard.NpcRole.VICTIM:
					var bad_guy = bad_guys.pick_random()
					var hideout = bad_guy.get_one_connection(Link.Type.HIDEOUT)
					match randi() % (3 if hideout else 2):
						0:
							location = bad_guy.get_home()
						1:
							location = bad_guy.get_work()
						2:
							location = hideout
				else:
					var victim = victims.pick_random()
					match randi() % (3 if secret_locations else 2):
						0:
							location = victim.get_home()
						1:
							location = victim.get_work()
						2:
							location = secret_locations.pick_random()

			if location_owner_count > 0:
				Card.add_bidirectional_connection(Link.Type.PROPERTY, obj, location)

			Card.add_bidirectional_connection(Link.Type.FOUND, obj, location)

			evidence.append(obj)

	# populate all locations with useless objects

	for card: LocationCard in locations:
		var obj_count = randi_range(0, 3)
		while obj_count > 0:
			var obj_id = _object_data.keys().pick_random()
			var owner_counts = _get_object_owner_counts(obj_id)
			var npc_owner_count = owner_counts[0]
			var location_owner_count = owner_counts[1]

			# find NPCs associated with the location (home, work, hangout,
			# hideout) to be designated owners of the object

			var location_npcs = card.get_all_npc_connections()
			if npc_owner_count <= location_npcs.size():
				var obj: ObjectCard = ObjectCard.create_card(obj_id)
				Card.add_bidirectional_connection(Link.Type.FOUND, card, obj)

				if npc_owner_count > 1:
					var candidates = location_npcs.duplicate()
					for i in npc_owner_count:
						var owner = candidates.pop_at(randi() % candidates.size())
						Card.add_bidirectional_connection(Link.Type.PROPERTY, obj, owner)
				elif npc_owner_count == 1:
					var owner = location_npcs.pick_random()
					Card.add_bidirectional_connection(Link.Type.PROPERTY, obj, owner)

				if location_owner_count > 0:
					Card.add_bidirectional_connection(Link.Type.PROPERTY, obj, card)

				other_objects.append(obj)
				obj_count -= 1

	# cards and links that are revealed initially

	for npc_list in [victims, witnesses, suspects]:
		for npc in npc_list:

			# victims are treated differently in the "final" case, where there
			# are multiple crime scenes: each dead victim is found in one of
			# those locations, and is not revealed initially

			if (crime_location_count > 1
				and npc.actual_role == NpcCard.NpcRole.VICTIM
				and npc.npc_status == NpcCard.NpcStatus.DEAD):
				continue

			npc.reveal_status = Card.RevealStatus.REVEALED
			var home = npc.get_home()
			var work = npc.get_work()
			var roll = 2 if home == work else randi() % 3
			if roll != 0 or home in _crime_locations:
				home.reveal_status = Card.RevealStatus.REVEALED
				create_link(npc, home, Link.Type.HOME, true, false)
			if roll != 1 or work in _crime_locations:
				work.reveal_status = Card.RevealStatus.REVEALED
				create_link(npc, work, Link.Type.WORK, true, false)

	for victim in victims:
		if victim.is_married:
			var partner = victim.get_spouse()
			partner.reveal_status = Card.RevealStatus.REVEALED
			var home = partner.get_home()
			if home.reveal_status == Card.RevealStatus.REVEALED:
				create_link(partner, home, Link.Type.HOME, true, false)

	for npc_list in [victims, witnesses, suspects]:
		for npc in npc_list:
			var partner = npc.get_spouse()
			if partner and partner.reveal_status == Card.RevealStatus.REVEALED:
				create_link(npc, partner, Link.Type.SPOUSE, true, false)

	for loc in _crime_locations:
		loc.reveal_status = Card.RevealStatus.REVEALED

func _get_count_from_array(count) -> int:
	if count is Array and not count.is_empty():
		return count.pick_random()
	else:
		return count

func _reveal_crime_scene_maybe(location: LocationCard, known_prob: float):
	var is_known
	if known_prob <= 0:
		is_known = false
	elif known_prob >= 1:
		is_known = true
	else:
		is_known = (randf() < known_prob)
	if is_known:
		location.location_status = LocationCard.LocationStatus.CRIME_SCENE
		_crime_locations.append(location)

func _create_new_connection(npc: NpcCard, link_type: Link.Type, ignore_count: int):
	var existing_cnx = npc.get_connections(link_type)
	var lambda = func(someone: NpcCard): return not someone in existing_cnx
	var other = _find_other_npc(npc, lambda, ignore_count)
	if other:
		Card.add_bidirectional_connection(link_type, npc, other)

func _find_partner_for(
		npc: NpcCard, ignore_count: int, married_ok: bool) -> NpcCard:
	var start_index = randi_range(ignore_count, npcs.size() - 1)
	var remainder = npcs.size() - ignore_count

	for i in remainder:
		var index = ignore_count + (start_index + i) % remainder

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
	if npc.is_married:
		_add_to_entourage(entourage, npc.get_spouse(), ignore_count)
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
		Card.add_bidirectional_connection(link_type, npc, frenemy)

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
		return candidates.pop_at(randi() % candidates.size())

	var lambda = func(other: NpcCard):
		return not (other in npc.get_connections(Link.Type.FRIEND) or
					other in npc.get_connections(Link.Type.ENEMY) or
					other in npc.get_connections(Link.Type.ACQUAINTANCE)) 

	return _find_other_npc(npc, lambda, ignore_count)

#
# Finds and returns an NPC who is not the given NPC, and for whom the given
# Callable returns true. Only NPCs whose index >= ignore_count are taken into
# consideration. Returns null if no eligible NPC is found.
#
func _find_other_npc(
	npc: NpcCard, filter: Callable = Callable(), ignore_count = 0) -> NpcCard:
	var start_index = randi_range(ignore_count, npcs.size() - 1)
	var remainder = npcs.size() - ignore_count

	for i in remainder:
		var index = ignore_count + (start_index + i) % remainder
		var other = npcs[index]
		if other != npc and (filter.is_null() or filter.call(other)):
			return other

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

#
# Returns the number of owners an object of the given type belongs to. An object
# can actually belong to a location as well as to one or more NPCs, so this
# function returns two integers: the number of NPC owners and the number of
# location "owners".
#
func _get_object_owner_counts(obj_id: String) -> Array:
	var owners = _object_data[obj_id].get("owners", {})
	var npc_owners = owners.get("npc", [0])
	var npc_owner_count = npc_owners.pick_random() as int
	var location_owners = owners.get("location", [0])
	var location_owner_count = location_owners.pick_random() as int
	return [npc_owner_count, location_owner_count]

##
## Creates a visible link of the given type from one card to another and returns
## it. Does nothing if there is already a link like that.
##
## If is_blocked is true, the link cannot be modified or deleted by the player.
## If is_new is true, the link is labelled as new until the player says so.
##
func create_link(
	from: Card, to: Card, type: Link.Type,
	is_blocked: bool, is_new: bool) -> Link:

	if from.find_link_to(to, type):
		return null

	var pin1 = Pin.allocate()
	var pos = from.to_global(Vector2(Card.size.x, 0))
	pin1.card_location = from.find_closest_unused_pin(pos)
	pin1.backing = from

	var pin2 = Pin.allocate()
	pos = to.to_global(Vector2(0, 0))
	pin2.card_location = to.find_closest_unused_pin(pos)
	pin2.backing = to

	var link = Link.allocate()
	link.type = type
	link.pin1 = pin1
	link.pin2 = pin2

	link.blocked = is_blocked
	link.status = Link.Status.NEW if is_new else Link.Status.CONFIRMED

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

func _generate_random_name() -> String:
	var name: String = ""
	while name.is_empty():
		name = (_case_name_data.part_1.pick_random() +
				_case_name_data.part_2.pick_random())
		for case in GameState.cases:
			if name == case.get_random_name():
				name = ""
				break
	return name

func get_case_id() -> String:
	return _case_id

func get_random_name() -> String:
	return _case_random_name

func get_case_name() -> String:
	return _case_name

func get_status() -> Status:
	return _status

func get_difficulty() -> int:
	return _difficulty

##
## Returns the number of days the player has to solve the case.
##
func get_duration() -> int:
	return _duration

##
## Returns the day the player took on the case.
##
func get_start_day() -> int:
	return _start_day

##
## Returns the day FOLLOWING the last day the player has to solve the case.
##
func get_end_day() -> int:
	return _start_day + _duration

##
## Returns the number of days left before the case expires.
##
func get_days_left() -> int:
	return get_end_day() - GameState.get_day()

##
## Returns true if the case has expired, that is, if get_days_left() returns a
## non-positive number.
##
func is_expired() -> bool:
	return get_end_day() <= GameState.get_day()

##
## Returns true if the case can still be abandoned. A case can be abandoned
## until N days before its deadline, where N is the case's difficulty. A case
## which is neither active nor paused cannot be abandoned.
##
func can_be_abandoned() -> bool:
	if _status in [Status.UNASSIGNED, Status.DONE]:
		return false
	return _start_day + _duration - GameState.get_day() >= _difficulty

##
## Returns the fee the player must pay if he wants to abandon the case.
##
func get_abandon_fee() -> int:
	return _difficulty * _duration + (GameState.get_day() - _start_day)

##
## Returns the crime location, if there is one, and if it is known. If there are
## multiple crime locations (which can happen only on the "final" case after an
## attack of paranoia), only the first is returned.
##
func get_crime_location() -> LocationCard:
	return null if _crime_locations.is_empty() else _crime_locations.front()

func get_motive_dictionary() -> Dictionary:
	return _motive

func get_victim_count() -> int:
	return _victim_count

func get_dead_victim_count() -> int:
	return _dead_victim_count

func get_culprit_count() -> int:
	return _culprit_count

func get_accomplice_count() -> int:
	return _accomplice_count

##
## Returns an array of the cards that have been revealed to the player thus far,
## that is, whose RevealStatus is REVEALED. Only NPCs (but not minions), objects
## and locations are ever "revealed".
##
func get_revealed_cards() -> Array[Card]:
	var cards: Array[Card]
	for card_list in [npcs, evidence, other_objects, locations]:
		for card in card_list:
			if card.reveal_status == Card.RevealStatus.REVEALED:
				cards.append(card)
	return cards

##
## Returns cards that have either been revealed to the player already or have
## not yet been revealed but are ready to be.
##
func get_unhidden_cards(revealed_cards, cards_in_limbo):
	for card_list in [npcs, evidence, other_objects, locations]:
		for card in card_list:
			match card.reveal_status:
				Card.RevealStatus.LIMBO:
					cards_in_limbo.append(card)
				Card.RevealStatus.REVEALED:
					revealed_cards.append(card)

func add_link(link: Link):
	_links.append(link)

func remove_link(link: Link):
	_links.erase(link)

func get_links() -> Array[Link]:
	return _links

#
# Looks for an existing location with the given ID, or creates a new one if
# none is found.
#
func _find_or_create_location(location_id: String) -> LocationCard:
	for card in locations:
		if card.database_id == location_id:
			return card
	return _create_location(location_id)

#
# Creates a new location card from the given ID in the location database.
#
func _create_location(location_id: String) -> LocationCard:
	var card = LocationCard.create_card(location_id)
	locations.append(card)
	return card

#
# Finds or creates a random hangout or hideout location.
#
func _find_hangout_or_hideout(hideout: bool) -> LocationCard:
	var candidates = []
	var criterion = "secret" if hideout else "yes"
	for loc in _location_data:
		if criterion in _location_data[loc].get("hangout", []):
			candidates.append(loc)
	return _find_or_create_location(candidates.pick_random())

##
## Returns a list of all existing locations in this case that could be used as
## a hangout.
##
func get_all_potential_hangouts() -> Array[LocationCard]:
	var hangouts: Array[LocationCard]
	for loc: LocationCard in locations:
		if "yes" in _location_data[loc.database_id]:
			hangouts.append(loc)
	return hangouts

func start():
	_status = Status.ACTIVE
	_start_day = GameState.get_day()

func pause():
	_status = Status.PAUSED

func close():
	_status = Status.DONE

##
## Updates the apparent roles of NPCs based on the guilt/proof links that have
## been created by the player. Also updates the "evidence" tag of objects,
## depending on whether or not they are linked to a culprit or an accomplice.
##
## Call this after the player creates, modifies or removes any guilt/proof
## links.
##
func update_npc_roles():
	var culprit_id_count_before = _get_identified_culprit_count()

	# start by restoring NPCs whose apparent roles are culprit or accomplice to
	# their default roles

	for npc in npcs:
		if npc.apparent_role in [
				NpcCard.NpcRole.CULPRIT, NpcCard.NpcRole.ACCOMPLICE]:
			if npc.actual_role in [
					NpcCard.NpcRole.VICTIM,
					NpcCard.NpcRole.SUSPECT,
					NpcCard.NpcRole.WITNESS]:
				npc.apparent_role = npc.actual_role
			else:
				npc.apparent_role = NpcCard.NpcRole.NONE

	# NPCs that are linked to a victim are labeled culprits (except for victims,
	# whose roles never change)

	for link in _links:
		if (link.type == Link.Type.GUILT
			and link.pin1.backing is NpcCard
			and link.pin2.backing is NpcCard):
			var card1: NpcCard = link.pin1.backing
			var card2: NpcCard = link.pin2.backing
			if card1.apparent_role == NpcCard.NpcRole.VICTIM:
				if card2.actual_role != NpcCard.NpcRole.VICTIM:
					card2.apparent_role = NpcCard.NpcRole.CULPRIT
			elif card2.apparent_role == NpcCard.NpcRole.VICTIM:
				if card1.actual_role != NpcCard.NpcRole.VICTIM:
					card1.apparent_role = NpcCard.NpcRole.CULPRIT

	# NPCs that are linked to a culprit are labeled accomplices (except for
	# victims, whose roles never change)

	for link in _links:
		if (link.type == Link.Type.GUILT
			and link.pin1.backing is NpcCard
			and link.pin2.backing is NpcCard):
			var card1: NpcCard = link.pin1.backing
			var card2: NpcCard = link.pin2.backing
			if card1.apparent_role == NpcCard.NpcRole.CULPRIT:
				if card2.actual_role != NpcCard.NpcRole.VICTIM:
					card2.apparent_role = NpcCard.NpcRole.ACCOMPLICE
			elif card2.apparent_role == NpcCard.NpcRole.CULPRIT:
				if card1.actual_role != NpcCard.NpcRole.VICTIM:
					card1.apparent_role = NpcCard.NpcRole.ACCOMPLICE

	# objects that are linked to a culprit or to an accomplice are labeled as
	# evidence

	for object_array in [evidence, other_objects]:
		for obj in object_array:
			var is_evidence = false
			for card in obj.find_linked_cards(Link.Type.GUILT):
				if card is NpcCard and card.apparent_role in [
					NpcCard.NpcRole.CULPRIT, NpcCard.NpcRole.ACCOMPLICE
				]:
					is_evidence = true
			obj.is_object_evidence = is_evidence

	# if the player just correctly identified a culprit, sic a minion on him in
	# the next four hours

	if culprit_id_count_before == 0 and _get_identified_culprit_count() > 0:
		var now = GameState.get_time()
		if _next_minion_attack < now or _next_minion_attack >= now + 4:
			_next_minion_attack = now + 1 + randi() % 3

func _get_identified_culprit_count() -> int:
	var count = 0
	for npc in npcs:
		if (npc.actual_role == NpcCard.NpcRole.CULPRIT
			and npc.apparent_role == NpcCard.NpcRole.CULPRIT):
			count += 1
	return count

##
## Adds initial, visible links between a newly discovered NPC and a location (if
## the location is the NPC's place of work, hangout or hideout).
##
func add_links_between_npc_and_location(npc: NpcCard, location: LocationCard):
	for type in [Link.Type.WORK, Link.Type.HANGOUT, Link.Type.HIDEOUT]:
		if location in npc.get_connections(type):
			create_link(npc, location, type, type == Link.Type.WORK, true)

##
## Called every morning for as long as the case is active or paused. Whether
## the case is paused or not, each NPC's new_day() method is called to update
## his/her attributes. If the case is active, and the player has correctly
## identified one or more culprits, a minion attack may be scheduled for some
## time during the day.
##
func new_day():
	for npc in npcs:
		npc.new_day()
	if _minion:
		_minion.new_day()

	if _status != Status.ACTIVE:
		return

	var now = GameState.get_time()
	if _next_minion_attack < now and _get_identified_culprit_count() > 0:
		# attack probability = case difficulty * 2% for each time slot
		var attack_prob = 8 * _difficulty
		var attack_roll = randi() % 100
		if attack_roll < attack_prob:
			# NB. it is assumed that this method is called at 8 AM
			match attack_roll % 4:
				0:
					# morning
					_next_minion_attack = now + randi() % 4
				1:
					# afternoon
					_next_minion_attack = now + 4 + randi() % 4
				2:
					# evening
					_next_minion_attack = now + 8 + randi() % 4
				3:
					# night
					_next_minion_attack = now + 12 + randi() % 12

##
## Checks whether a minion is scheduled to attack the player in the next hour.
## If so, resets the time of the next minion attack and returns true.
##
func check_minion_attack() -> bool:
	var now: int = GameState.get_time()
	if _next_minion_attack >= now and _next_minion_attack <= now + 1:
		_next_minion_attack = -1
		return true
	return false

##
## Returns a minion to attack the player, creating one if necessary. If a
## minion survived a previous attack and was not sent to jail, the same minion
## is used again.
##
func fetch_minion() -> NpcCard:
	if _minion == null:
		_minion = NpcCard.generate_card(self, NpcCard.NpcRole.MINION)
	return _minion

##
## If a minion was created previously for this case, he/she is removed. Call
## this if the minion has been killed or sent to jail.
##
func forget_minion():
	if _minion:
		_minion.queue_free()
		_minion = null

##
## Checks whether the player has solved the case, by identifying the motive,
## culprits, accomplices, evidence and incriminating links. Returns HALF_RIGHT
## if he has identified all those except for the motive, or if he has also made
## a small number of incorrect links.
##
func check_solution() -> SolutionResult:
	var error_count = 0
	var right_motive = false
	var good_link_count = 0
	var bad_link_count = 0

	print("checking case solution:")

	# check crime and motive

	if not (selected_crime and selected_motive):
		print("❌ no motive selected")
		error_count += 1
	elif selected_crime != _crime:
		print("❌ wrong crime: %s" % selected_crime)
		error_count += 1
	elif _crime_data[selected_crime][selected_motive].name != _motive.name:
		print("❌ wrong motive: %s" % _crime_data[selected_crime][selected_motive].name)
	else:
		print("✅ identified crime and motive")
		right_motive = true

	# check culprits and accomplices

	for npc in npcs:
		if npc.actual_role == NpcCard.NpcRole.CULPRIT:
			if npc.apparent_role == NpcCard.NpcRole.CULPRIT:
				print("✅ identified culprit: %s" % npc.get_display_name())
				good_link_count += 1
			else:
				print("❌ culprit not found: %s" % npc.get_display_name())
				error_count += 1
		elif npc.actual_role == NpcCard.NpcRole.ACCOMPLICE:
			if npc.apparent_role == NpcCard.NpcRole.ACCOMPLICE:
				print("✅ identified accomplice: %s" % npc.get_display_name())
				good_link_count += 1
			else:
				print("❌ accomplice not found: %s" % npc.get_display_name())
				error_count += 1
		elif npc.apparent_role == NpcCard.NpcRole.CULPRIT:
			print("❌ not a culprit: %s" % npc.get_display_name())
			bad_link_count += 1
		elif npc.apparent_role == NpcCard.NpcRole.ACCOMPLICE:
			print("❌ not an accomplice: %s" % npc.get_display_name())
			bad_link_count += 1

	# check evidence

	for obj in evidence:
		if obj.is_object_evidence:
			print("✅ identified evidence: %s" % obj.get_display_name())
			good_link_count += 1
		else:
			print("❌ evidence not found: %s" % obj.get_display_name())
			error_count += 1

	for obj in other_objects:
		if obj.is_object_evidence:
			print("❌ not evidence: %s" % obj.get_display_name())
			bad_link_count += 1

	# check incriminating links

	for npc in npcs:
		if npc.actual_role != NpcCard.NpcRole.VICTIM:
			continue
		for link_type in Link.incriminating_types:
			var type_name = Link.Type.keys()[link_type].to_lower()
			for other in npc.get_connections(link_type):
				var link = npc.find_link_to(other, link_type)
				if link == null:
					print("❌ link not found: %s => %s" % [
						type_name, other.get_display_name()])
					error_count += 1
				elif link.status != Link.Status.CONFIRMED:
					print("❌ link not confirmed: %s => %s" % [
						type_name, other.get_display_name()])
					error_count += 1
				else:
					print("✅ link identified: %s => %s" % [
						type_name, other.get_display_name()])
					good_link_count += 1
			for link in npc.find_links(link_type):
				if link.status != Link.Status.CONFIRMED:
					continue
				var other
				if link.pin1.backing == npc:
					other = link.pin2.backing
				else:
					other = link.pin1.backing
				if other is NpcCard and not other.apparent_role in [
					NpcCard.NpcRole.CULPRIT, NpcCard.NpcRole.ACCOMPLICE]:
					continue
				if not other in npc.get_connections(link_type):
					print("❌ incorrect link: %s => %s" % [
						type_name, other.get_display_name()])
					bad_link_count += 1

	if error_count == 0 and right_motive and bad_link_count == 0:
		print("=> correct solution")
		return SolutionResult.RIGHT
	elif error_count > 0 or bad_link_count * 3 > good_link_count:
		print("=> wrong solution")
		return SolutionResult.WRONG
	else:
		print("=> half solution")
		return SolutionResult.HALF_RIGHT

func print_case():
	print()
	print("************************************************************")
	print(_case_name)
	print("************************************************************")
	print()
	print("difficulty: ", _difficulty)
	for npc in npcs:
		print()
		npc.print_npc()
	for obj in evidence:
		print()
		obj.print_object()

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
	if _minion:
		refs.append(_minion)
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
		"case_random_name": _case_random_name,
		"case_name": _case_name,
		"crime": _crime,
		"motive": _motive,
		"victim_count": _victim_count,
		"dead_victim_count": _dead_victim_count,
		"culprit_count": _culprit_count,
		"accomplice_count": _accomplice_count,
		"difficulty": _difficulty,
		"duration": _duration,
		"status": _status,
		"start_day": _start_day,
		"next_minion_attack": _next_minion_attack,
		"selected_crime": selected_crime,
		"selected_motive": selected_motive,
		"is_layout_needed": is_layout_needed,
	}

	if npcs:
		var npc_refs = []
		for npc in npcs:
			npc_refs.append(npc.get_unique_id())
		dict["npcs"] = npc_refs

	if _minion:
		dict["minion"] = _minion.get_unique_id()

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

	if _crime_locations:
		var location_refs = []
		for card in _crime_locations:
			location_refs.append(card.get_unique_id())
		dict["crime_locations"] = location_refs

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
	_case_random_name = dict.get("case_random_name", "Bork Bork Bork")
	_case_name = dict.case_name
	_crime = dict.crime
	_motive = dict.motive
	_victim_count = dict.get("victim_count", 0)
	_dead_victim_count = dict.get("dead_victim_count", 0)
	_culprit_count = dict.get("culprit_count", 0)
	_accomplice_count = dict.get("accomplice_count", 0)
	_difficulty = dict.difficulty
	_duration = dict.duration
	_status = dict.status
	_start_day = dict.get("start_day", -1)
	_next_minion_attack = dict.get("next_minion_attack", -1)
	selected_crime = dict.get("selected_crime", "")
	selected_motive = dict.get("selected_motive", "")
	is_layout_needed = dict.get("is_layout_needed", true)
	for ref in dict.get("npcs", []):
		npcs.append(catalog[ref])
	if "minion" in dict:
		_minion = catalog[dict.minion]
	for ref in dict.get("evidence", []):
		evidence.append(catalog[ref])
	for ref in dict.get("other_objects", []):
		other_objects.append(catalog[ref])
	for ref in dict.get("locations", []):
		locations.append(catalog[ref])
	if "crime_locations" in dict:
		for ref in dict.crime_locations:
			_crime_locations.append(catalog[ref])
	elif "crime_location" in dict:
		_crime_locations.append(catalog[dict.crime_location])
	for ref in dict.get("links", []):
		_links.append(catalog[ref])

#
# For save/load.
#
static func allocate() -> Object:
	return Case.new()
