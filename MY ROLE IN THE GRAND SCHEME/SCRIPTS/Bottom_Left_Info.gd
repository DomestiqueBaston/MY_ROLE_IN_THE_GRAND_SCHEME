extends Node2D

## Class that visualizes everything the player thinks he knows about a given
## card. Call show_card() to show the contents of a given card, or clear() to
## show nothing. show_location() allows you to visualize information about a
## few predefined player locations (office, investigation center, etc.) in
## addition to locations defined by cards.

@export var size := Vector2(114, 144)

var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data

func _ready():
	$VBox.size = size

##
## Shows nothing.
##
func clear():
	$VBox/Scroller_Object.hide()
	$VBox/Scroller_Location.hide()
	$VBox/Scroller_NPC.hide()
	$VBox/Scroller_Other.hide()

##
## Shows the player everthing he thinks he knows about the given card, as
## determined namely by the links he has created to it.
##
func show_card(card: Card):
	match card.get_card_type():
		Card.CardType.OBJECT:
			show_object(card)
		Card.CardType.LOCATION:
			show_location(GameState.PlayerLocation.OTHER, card)
		Card.CardType.NPC:
			show_npc(card)
		_:
			show_other(card)

##
## Shows predefined information about the given Combat, Invesigation, Dialogue
## or Abstract card.
##
func show_other(card: Card):
	if card.get_card_type() in [
		Card.CardType.COMBAT,
		Card.CardType.INVESTIGATION,
		Card.CardType.DIALOGUE,
		Card.CardType.ABSTRACT
	]:
		$VBox/Scroller_Other/Info.text = card.get_info()
		$VBox/Scroller_Object.hide()
		$VBox/Scroller_Location.hide()
		$VBox/Scroller_NPC.hide()
		$VBox/Scroller_Other.show()
	else:
		clear()

##
## Similar to show_card(), when it is given a location card, but this function
## also supports a number of predefined locations not defined by cards: see the
## GameState.PlayerLocation enum. If loc is GameState.PlayerLocation.OTHER, then
## card must be the card defining the location; otherwise card must not be
## given.
##
func show_location(loc: GameState.PlayerLocation, card: LocationCard = null):
	for node in $VBox/Scroller_Location/Info_Location.get_children():
		node.hide()

	var loc_name = ""
	var loc_desc = ""

	match loc:
		GameState.PlayerLocation.OFFICE:
			loc_name = "- IN THE OFFICE -"
			loc_desc = "Chaos reigns here, the files are trying to escape, and your sanity's the only thing more disorganized than the paperwork."
		GameState.PlayerLocation.INVESTIGATION_CENTER:
			loc_name = "- AT THE -\n- INVESTIGATION -\n- CENTER -"
			loc_desc = "Where you come for a job, and leave with more problems than you came for."
		GameState.PlayerLocation.DOCTOR:
			loc_name = "- AT DOCTOR F.'S -"
			loc_desc = "Where your health issues are always bigger than the bill."
		GameState.PlayerLocation.ROWENA:
			loc_name = "- AT ROWENA'S -"
			loc_desc = "You come here for a fix, but eventually leave with more problems than you came with."
		GameState.PlayerLocation.WARRANT_DESK:
			loc_name = "- AT THE -\n- WARRANT DESK -"
			loc_desc = "Where paperwork meets trouble (and trouble always wins)."
		GameState.PlayerLocation.PRISON:
			loc_name = "- IN JAIL -"
			loc_desc = "Where you learn how to make your next big mistake..."
		GameState.PlayerLocation.OTHER:
			var info = _location_data[card.database_id]
			loc_name = info["info_name"]
			loc_desc = info["description"]

	$VBox/Scroller_Location/Info_Location/Name.text = loc_name
	$VBox/Scroller_Location/Info_Location/Description.text = loc_desc
	$VBox/Scroller_Location/Info_Location/Name.show()
	$VBox/Scroller_Location/Info_Location/Separator_01.show()
	$VBox/Scroller_Location/Info_Location/Description.show()

	if card:
		if card.location_status == LocationCard.LocationStatus.CRIME_SCENE:
			$VBox/Scroller_Location/Info_Location/Crime_Scene.show()

		var inhabitants = card.find_links(Link.Type.HOME)
		if inhabitants:
			$VBox/Scroller_Location/Info_Location/Separator_02.show()
			$VBox/Scroller_Location/Info_Location/Home.show()
			$VBox/Scroller_Location/Info_Location/Home_NPC_01.text = \
				_make_link_list(card, inhabitants)
			$VBox/Scroller_Location/Info_Location/Home_NPC_01.show()

		var workers = card.find_links(Link.Type.WORK)
		if workers:
			$VBox/Scroller_Location/Info_Location/Separator_03.show()
			$VBox/Scroller_Location/Info_Location/Workplace.show()
			$VBox/Scroller_Location/Info_Location/Workplace_NPC_01.text = \
				_make_link_list(card, workers)
			$VBox/Scroller_Location/Info_Location/Workplace_NPC_01.show()

		var hours = card.opening_hours

		$VBox/Scroller_Location/Info_Location/Separator_04.show()
		$VBox/Scroller_Location/Info_Location/Hours.show()
		if hours == 0:
			$VBox/Scroller_Location/Info_Location/Time_Slot_None.show()
		elif hours == GameState.TimeSlot.ALWAYS:
			$VBox/Scroller_Location/Info_Location/Time_Slot_H24.show()
		else:
			var weekday_hours: Array[String]
			if hours & GameState.TimeSlot.MORNING:
				weekday_hours.append("8 AM")
				weekday_hours.append("12 PM")
			if hours & GameState.TimeSlot.AFTERNOON:
				if not weekday_hours.is_empty() and weekday_hours[-1] == "12 PM":
					weekday_hours[-1] = "4 PM"
				else:
					weekday_hours.append("12 PM")
					weekday_hours.append("4 PM")
			if hours & GameState.TimeSlot.EVENING:
				if not weekday_hours.is_empty() and weekday_hours[-1] == "4 PM":
					weekday_hours[-1] = "8 PM"
				else:
					weekday_hours.append("4 PM")
					weekday_hours.append("8 PM")
			if hours & GameState.TimeSlot.NIGHT:
				if not weekday_hours.is_empty() and weekday_hours[-1] == "8 PM":
					weekday_hours[-1] = "8 AM"
				else:
					weekday_hours.append("8 PM")
					weekday_hours.append("8 AM")

			var weekend_hours: Array[String]
			if hours & GameState.TimeSlot.WE_MORNING:
				weekend_hours.append("8 AM")
				weekend_hours.append("12 PM")
			if hours & GameState.TimeSlot.WE_AFTERNOON:
				if not weekend_hours.is_empty() and weekend_hours[-1] == "12 PM":
					weekend_hours[-1] = "4 PM"
				else:
					weekend_hours.append("12 PM")
					weekend_hours.append("4 PM")
			if hours & GameState.TimeSlot.WE_EVENING:
				if not weekend_hours.is_empty() and weekend_hours[-1] == "4 PM":
					weekend_hours[-1] = "8 PM"
				else:
					weekend_hours.append("4 PM")
					weekend_hours.append("8 PM")
			if hours & GameState.TimeSlot.WE_NIGHT:
				if not weekend_hours.is_empty() and weekend_hours[-1] == "8 PM":
					weekend_hours[-1] = "8 AM"
				else:
					weekend_hours.append("8 PM")
					weekend_hours.append("8 AM")

			var open_text = ""

			if not weekday_hours.is_empty() \
				and (weekend_hours.is_empty() or weekend_hours == weekday_hours):
				for i in range(0, weekday_hours.size(), 2):
					if not open_text.is_empty():
						open_text += "\n"
					open_text += weekday_hours[i]
					open_text += " - "
					open_text += weekday_hours[i+1]
			elif weekday_hours.is_empty() and not weekend_hours.is_empty():
				for i in range(0, weekend_hours.size(), 2):
					if not open_text.is_empty():
						open_text += "\n"
					open_text += weekend_hours[i]
					open_text += " - "
					open_text += weekend_hours[i+1]
			else:
				for i in range(0, weekday_hours.size(), 2):
					if not open_text.is_empty():
						open_text += "\n"
					open_text += weekday_hours[i]
					open_text += " - "
					open_text += weekday_hours[i+1]
					open_text += " Mon-Fri"
				for i in range(0, weekend_hours.size(), 2):
					if not open_text.is_empty():
						open_text += "\n"
					open_text += weekend_hours[i]
					open_text += " - "
					open_text += weekend_hours[i+1]
					open_text += " Sat-Sun"

			$VBox/Scroller_Location/Info_Location/Time_Slots.text = open_text
			$VBox/Scroller_Location/Info_Location/Time_Slots.show()

		$VBox/Scroller_Location/Info_Location/Separator_05.show()
		$VBox/Scroller_Location/Info_Location/Weekend.show()
		if hours == 0:
			$VBox/Scroller_Location/Info_Location/Weekend_day_01.show()
		elif (hours & GameState.TimeSlot.WEEKEND) != 0:
			$VBox/Scroller_Location/Info_Location/Weekend_day_02.show()
		else:
			$VBox/Scroller_Location/Info_Location/Weekend_day_03.show()

		var hangout = card.find_links(Link.Type.HANGOUT)
		if hangout:
			$VBox/Scroller_Location/Info_Location/Separator_06.show()
			$VBox/Scroller_Location/Info_Location/Hangout.show()
			$VBox/Scroller_Location/Info_Location/Hangout_NPC_01.text = \
				_make_link_list(card, hangout)
			$VBox/Scroller_Location/Info_Location/Hangout_NPC_01.show()

		var hideout = card.find_links(Link.Type.HIDEOUT)
		if hideout:
			$VBox/Scroller_Location/Info_Location/Separator_08.show()
			$VBox/Scroller_Location/Info_Location/Hideout.show()
			$VBox/Scroller_Location/Info_Location/Hideout_NPC_01.text = \
				_make_link_list(card, hideout)
			$VBox/Scroller_Location/Info_Location/Hideout_NPC_01.show()

	$VBox/Scroller_Object.hide()
	$VBox/Scroller_Location.show()
	$VBox/Scroller_NPC.hide()
	$VBox/Scroller_Other.hide()

##
## Shows the player everthing he thinks he knows about the given object card, as
## determined namely by the links he has created to it.
##
func show_object(obj: ObjectCard):
	for node in $VBox/Scroller_Object/Info_Object.get_children():
		node.hide()

	var info = _object_data[obj.database_id]
	$VBox/Scroller_Object/Info_Object/Name.text = info["info_name"]
	$VBox/Scroller_Object/Info_Object/Description.text = info["description"]

	$VBox/Scroller_Object/Info_Object/Name.show()
	$VBox/Scroller_Object/Info_Object/Separator_01.show()
	$VBox/Scroller_Object/Info_Object/Description.show()

	var locations = obj.find_links(Link.Type.FOUND)
	if locations:
		$VBox/Scroller_Object/Info_Object/Separator_02.show()
		$VBox/Scroller_Object/Info_Object/Found.show()
		$VBox/Scroller_Object/Info_Object/Found_Location.text = \
			_make_link_list(obj, locations)
		$VBox/Scroller_Object/Info_Object/Found_Location.show()

	var owners = obj.find_links(Link.Type.PROPERTY).filter(
		func(card): return card is NpcCard)
	if owners:
		$VBox/Scroller_Object/Info_Object/Separator_03.show()
		$VBox/Scroller_Object/Info_Object/Property.show()
		$VBox/Scroller_Object/Info_Object/Property_NPC.text = \
			_make_link_list(obj, owners)
		$VBox/Scroller_Object/Info_Object/Property_NPC.show()

	if obj.is_object_evidence:
		$VBox/Scroller_Object/Info_Object/Separator_04.show()
		$VBox/Scroller_Object/Info_Object/Evidence.show()

	$VBox/Scroller_Object.show()
	$VBox/Scroller_Location.hide()
	$VBox/Scroller_NPC.hide()
	$VBox/Scroller_Other.hide()

##
## Shows the player everthing he thinks he knows about the given NPC card, as
## determined namely by the links he has created to it.
##
func show_npc(npc: NpcCard):
	for node in $VBox/Scroller_NPC/Info_NPC.get_children():
		node.hide()

	$VBox/Scroller_NPC/Info_NPC/NPC_Name.text = npc.get_display_name()
	$VBox/Scroller_NPC/Info_NPC/NPC.show()
	$VBox/Scroller_NPC/Info_NPC/Separator_17.show()
	$VBox/Scroller_NPC/Info_NPC/NPC_Name.show()

	var health_label: Control

	match npc.npc_health:
		NpcCard.NpcHealth.GOOD:
			health_label = $VBox/Scroller_NPC/Info_NPC/Health_Good
		NpcCard.NpcHealth.AVERAGE:
			health_label = $VBox/Scroller_NPC/Info_NPC/Health_Average
		NpcCard.NpcHealth.LOW:
			health_label = $VBox/Scroller_NPC/Info_NPC/Health_Low

	if health_label:
		$VBox/Scroller_NPC/Info_NPC/Separator_01.show()
		$VBox/Scroller_NPC/Info_NPC/Health.show()
		health_label.show()

	var status_label: Control
	var role_label: Control

	match npc.npc_status:
		NpcCard.NpcStatus.JAIL:
			status_label = $VBox/Scroller_NPC/Info_NPC/Status_In_Jail
		NpcCard.NpcStatus.DEAD:
			status_label = $VBox/Scroller_NPC/Info_NPC/Status_Dead
		NpcCard.NpcStatus.DISAPPEARED:
			status_label = $VBox/Scroller_NPC/Info_NPC/Status_Disappeared

	match npc.apparent_role:
		NpcCard.NpcRole.VICTIM:
			role_label = $VBox/Scroller_NPC/Info_NPC/Status_Victim
		NpcCard.NpcRole.SUSPECT:
			role_label = $VBox/Scroller_NPC/Info_NPC/Status_Suspect
		NpcCard.NpcRole.WITNESS:
			role_label = $VBox/Scroller_NPC/Info_NPC/Status_Witness
		NpcCard.NpcRole.CULPRIT:
			role_label = $VBox/Scroller_NPC/Info_NPC/Status_Culprit
		NpcCard.NpcRole.ACCOMPLICE:
			role_label = $VBox/Scroller_NPC/Info_NPC/Status_Accomplice
		NpcCard.NpcRole.MINION:
			role_label = $VBox/Scroller_NPC/Info_NPC/Status_Minion

	$VBox/Scroller_NPC/Info_NPC/Separator_02.show()
	$VBox/Scroller_NPC/Info_NPC/Status.show()

	if status_label or role_label:
		if status_label:
			status_label.show()
		if role_label:
			role_label.show()
	else:
		$VBox/Scroller_NPC/Info_NPC/Status_None.show()

	var intimates = npc.find_links(Link.Type.INTIMACY)
	var partners: Array[Link]
	var affairs: Array[Link]

	if npc.is_married:
		partners = intimates.slice(0, 1)
		affairs = intimates.slice(1, intimates.size())
	else:
		affairs = intimates

	if partners:
		$VBox/Scroller_NPC/Info_NPC/Separator_03.show()
		$VBox/Scroller_NPC/Info_NPC/Couple.show()
		$VBox/Scroller_NPC/Info_NPC/Couple_NPC.text = \
			_make_link_list(npc, partners)
		$VBox/Scroller_NPC/Info_NPC/Couple_NPC.show()

	var friends = npc.find_links(Link.Type.FRIEND)
	if friends:
		$VBox/Scroller_NPC/Info_NPC/Separator_04.show()
		$VBox/Scroller_NPC/Info_NPC/Friends.show()
		$VBox/Scroller_NPC/Info_NPC/Friends_NPC_01.text = \
			_make_link_list(npc, friends)
		$VBox/Scroller_NPC/Info_NPC/Friends_NPC_01.show()

	var enemies = npc.find_links(Link.Type.ENEMY)
	if enemies:
		$VBox/Scroller_NPC/Info_NPC/Separator_05.show()
		$VBox/Scroller_NPC/Info_NPC/Enemies.show()
		$VBox/Scroller_NPC/Info_NPC/Enemies_NPC_01.text = \
			_make_link_list(npc, enemies)
		$VBox/Scroller_NPC/Info_NPC/Enemies_NPC_01.show()

	var acquaintances = npc.find_links(Link.Type.ACQUAINTANCE)
	if acquaintances:
		$VBox/Scroller_NPC/Info_NPC/Separator_06.show()
		$VBox/Scroller_NPC/Info_NPC/Acquaintance.show()
		$VBox/Scroller_NPC/Info_NPC/Acquaintance_NPC_01.text = \
			_make_link_list(npc, acquaintances)
		$VBox/Scroller_NPC/Info_NPC/Acquaintance_NPC_01.show()

	if affairs:
		$VBox/Scroller_NPC/Info_NPC/Separator_07.show()
		$VBox/Scroller_NPC/Info_NPC/Affair.show()
		$VBox/Scroller_NPC/Info_NPC/Affair_NPC.text = \
			_make_link_list(npc, affairs)
		$VBox/Scroller_NPC/Info_NPC/Affair_NPC.show()

	var debts = npc.find_links(Link.Type.DEBT)
	if debts:
		$VBox/Scroller_NPC/Info_NPC/Separator_08.show()
		$VBox/Scroller_NPC/Info_NPC/Debt_Influence.show()
		$VBox/Scroller_NPC/Info_NPC/Debt_Influence_NPC_01.text = \
			_make_link_list(npc, debts)
		$VBox/Scroller_NPC/Info_NPC/Debt_Influence_NPC_01.show()

	var ideology = npc.find_links(Link.Type.IDEOLOGY)
	if ideology:
		$VBox/Scroller_NPC/Info_NPC/Separator_09.show()
		$VBox/Scroller_NPC/Info_NPC/Ideology.show()
		$VBox/Scroller_NPC/Info_NPC/Ideology_NPC_01.text = \
			_make_link_list(npc, ideology)
		$VBox/Scroller_NPC/Info_NPC/Ideology_NPC_01.show()

	var work = npc.find_links(Link.Type.WORK)

	$VBox/Scroller_NPC/Info_NPC/Separator_10.show()
	$VBox/Scroller_NPC/Info_NPC/Schedule.show()
	if work.is_empty():
		$VBox/Scroller_NPC/Info_NPC/Schedule_None.show()
	elif npc.work_shifts & GameState.TimeSlot.NIGHT:
		$VBox/Scroller_NPC/Info_NPC/Schedule_Night.show()
	elif (npc.work_shifts & GameState.TimeSlot.MORNING) == 0:
		$VBox/Scroller_NPC/Info_NPC/Schedule_Aft_Eve.show()
	elif (npc.work_shifts & GameState.TimeSlot.AFTERNOON) == 0:
		$VBox/Scroller_NPC/Info_NPC/Schedule_Morn_Eve.show()
	else:
		$VBox/Scroller_NPC/Info_NPC/Schedule_Morn_Aft.show()

	$VBox/Scroller_NPC/Info_NPC/Separator_11.show()
	$VBox/Scroller_NPC/Info_NPC/Weekend.show()
	if work.is_empty():
		$VBox/Scroller_NPC/Info_NPC/Weekend_None.show()
	elif npc.has_weekend_shift:
		$VBox/Scroller_NPC/Info_NPC/Weekend_Mon_Tue.show()
	else:
		$VBox/Scroller_NPC/Info_NPC/Weekend_Sat_Sun.show()

	var home = npc.find_links(Link.Type.HOME)
	if home:
		$VBox/Scroller_NPC/Info_NPC/Separator_12.show()
		$VBox/Scroller_NPC/Info_NPC/Home.show()
		$VBox/Scroller_NPC/Info_NPC/Home_Location.text = \
			_make_link_list(npc, home)
		$VBox/Scroller_NPC/Info_NPC/Home_Location.show()

	if work:
		$VBox/Scroller_NPC/Info_NPC/Separator_13.show()
		$VBox/Scroller_NPC/Info_NPC/Work.show()
		$VBox/Scroller_NPC/Info_NPC/Work_Location.text = \
			_make_link_list(npc, work)
		$VBox/Scroller_NPC/Info_NPC/Work_Location.show()

	var hangout = npc.find_links(Link.Type.HANGOUT)
	if hangout:
		$VBox/Scroller_NPC/Info_NPC/Separator_14.show()
		$VBox/Scroller_NPC/Info_NPC/Hangout.show()
		$VBox/Scroller_NPC/Info_NPC/Hangout_Location.text = \
			_make_link_list(npc, hangout)
		$VBox/Scroller_NPC/Info_NPC/Hangout_Location.show()

	var hideout = npc.find_links(Link.Type.HIDEOUT)
	if hideout:
		$VBox/Scroller_NPC/Info_NPC/Separator_15.show()
		$VBox/Scroller_NPC/Info_NPC/Hideout.show()
		$VBox/Scroller_NPC/Info_NPC/Hideout_Location.text = \
			_make_link_list(npc, hideout)
		$VBox/Scroller_NPC/Info_NPC/Hideout_Location.show()

	var property = npc.find_links(Link.Type.PROPERTY)
	if property:
		$VBox/Scroller_NPC/Info_NPC/Separator_16.show()
		$VBox/Scroller_NPC/Info_NPC/Properties.show()
		$VBox/Scroller_NPC/Info_NPC/Properties_Object.text = \
			_make_link_list(npc, property)
		$VBox/Scroller_NPC/Info_NPC/Properties_Object.show()

	$VBox/Scroller_Object.hide()
	$VBox/Scroller_Location.hide()
	$VBox/Scroller_NPC.show()
	$VBox/Scroller_Other.hide()

func _make_link_list(card: Card, links: Array[Link]) -> String:
	var text = ""
	for link in links:
		var other_card
		if not (link.pin1.backing is Card and link.pin2.backing is Card):
			continue
		if link.pin1.backing == card:
			other_card = link.pin2.backing
		else:
			other_card = link.pin1.backing
		if other_card == null:
			continue
		if not text.is_empty():
			text += "\n"
		if link.status == Link.Status.PROBABLE:
			text += "[color=cf231796]"
		text += other_card.get_display_name()
		if other_card is ObjectCard and other_card.is_object_evidence:
			text += " (evidence)"
		if link.status == Link.Status.PROBABLE:
			text += "[/color]"
	return text
