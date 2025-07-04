class_name Case extends RefCounted

enum Status {
	UNASSIGNED,
	ACTIVE,
	PAUSED,
	DONE
}

var case_name: String
var crime: String
var motive: Dictionary
var difficulty: int
var duration: int
var status: Status = Status.UNASSIGNED

var culprits: Array[NpcCard]
var victims: Array[NpcCard]
var witnesses: Array[NpcCard]
var accomplices: Array[NpcCard]
var suspects: Array[NpcCard]
var other_npcs: Array[NpcCard]
var evidence: Array[ObjectCard]
var crime_location: LocationCard

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

func _notification(what: int):
	# Cards are Nodes, not RefCounted, so they must be deleted explicitly
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

static func generate() -> Case:
	var case = Case.new()
	case._randomize()
	return case

func _randomize():

	# crime, motive and lots of other information about the case

	crime = GameState.get_new_crime()
	motive = _crime_data[crime].pick_random()
	case_name = motive["name"]

	# NPCs: culprits

	culprits = _generate_npcs(
		motive.get("culprits", 0), NpcCard.NpcStatus.NONE,
		motive.get("culprits_professions", []))

	# NPCs: victims

	victims = _generate_npcs(
		motive.get("victims", 0), NpcCard.NpcStatus.VICTIM,
		motive.get("victims_professions", []))

	if victims:
		var dead = motive["dead_victims"]
		for card in victims:
			if dead == "yes":
				card.npc_status = NpcCard.NpcStatus.DEAD
			elif dead == "disappeared":
				card.npc_status = NpcCard.NpcStatus.DISAPPEARED
			elif dead == "random":
				if randi() & 1:
					card.npc_status = NpcCard.NpcStatus.DEAD

	# NPCs: witnesses, accomplices, suspects

	witnesses = _generate_npcs(motive.get("witnesses", 0), NpcCard.NpcStatus.WITNESS)
	accomplices = _generate_npcs(motive.get("accomplices", 0))
	suspects = _generate_npcs(motive.get("suspects", 0), NpcCard.NpcStatus.SUSPECT)

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
	difficulty = clampi(roundi(diff), 1, 5)

	if difficulty == 6:
		duration = 15 + randi_range(-2, 2)
	else:
		duration = roundi((difficulty * 4 + 10) * randf_range(0.9, 1.1))

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
		var known_factor = motive.get("known_crime_location", 1)
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
		card.npc_status = status
		cards.append(card)
	return cards

func get_cards() -> Array[BaseCard]:
	var all_cards: Array[BaseCard]
	for npcs in [culprits, victims, witnesses, accomplices, suspects, other_npcs]:
		all_cards.append_array(npcs)
		for npc in npcs:
			all_cards.append(npc.get_home())
			all_cards.append(npc.get_work())
	all_cards.append_array(evidence)
	if crime_location:
		all_cards.append(crime_location)
	return all_cards

# TODO: function to return links

func start():
	status = Status.ACTIVE

func pause():
	status = Status.PAUSED
