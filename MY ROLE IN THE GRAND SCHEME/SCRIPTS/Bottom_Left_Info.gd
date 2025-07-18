extends Node2D

var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
var _object_data = preload("res://JSON/OBJECT_LOCATION/Object.json").data

func clear():
	$Scroller_Object.hide()
	$Scroller_NPC.hide()
	$Scroller_Location.hide()

func show_card(card: BaseCard):
	if card is LocationCard:
		show_location(GameState.PlayerLocation.OTHER, card)
	elif card is ObjectCard:
		show_object(card)
	elif card is NpcCard:
		show_npc(card)
	else:
		clear()

func show_location(loc: GameState.PlayerLocation, card: LocationCard = null):
	for node in $Scroller_Location/Info_Location.get_children():
		node.hide()

	var loc_name = ""
	var loc_desc = ""

	match loc:
		GameState.PlayerLocation.OFFICE:
			loc_name = "- AT THE OFFICE -"
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

	$Scroller_Location/Info_Location/Name.text = loc_name
	$Scroller_Location/Info_Location/Description.text = loc_desc
	$Scroller_Location/Info_Location/Name.show()
	$Scroller_Location/Info_Location/Separator_01.show()
	$Scroller_Location/Info_Location/Description.show()

	if card:
		var case = GameState.get_current_case()

		if card.location_status == LocationCard.LocationStatus.CRIME_SCENE:
			$Scroller_Location/Info_Location/Crime_Scene.show()

		var inhabitants = case.find_links_to(card, Link.Type.HOME)
		if inhabitants:
			$Scroller_Location/Info_Location/Separator_02.show()
			$Scroller_Location/Info_Location/Home.show()
			$Scroller_Location/Info_Location/Home_NPC_01.text = _make_card_list(inhabitants)
			$Scroller_Location/Info_Location/Home_NPC_01.show()

		var workers = case.find_links_to(card, Link.Type.WORK)
		if workers:
			$Scroller_Location/Info_Location/Separator_03.show()
			$Scroller_Location/Info_Location/Workplace.show()
			$Scroller_Location/Info_Location/Workplace_NPC_01.text = _make_card_list(workers)
			$Scroller_Location/Info_Location/Workplace_NPC_01.show()

		var hangout = case.find_links_to(card, Link.Type.HANGOUT)
		if hangout:
			$Scroller_Location/Info_Location/Separator_06.show()
			$Scroller_Location/Info_Location/Hangout.show()
			$Scroller_Location/Info_Location/Hangout_NPC_01.text = _make_card_list(hangout)
			$Scroller_Location/Info_Location/Hangout_NPC_01.show()

		var hideout = case.find_links_to(card, Link.Type.HIDEOUT)
		if hideout:
			$Scroller_Location/Info_Location/Separator_08.show()
			$Scroller_Location/Info_Location/Hideout.show()
			$Scroller_Location/Info_Location/Hideout_NPC_01.text = _make_card_list(hideout)
			$Scroller_Location/Info_Location/Hideout_NPC_01.show()

	$Scroller_Object.hide()
	$Scroller_NPC.hide()
	$Scroller_Location.show()

func show_object(obj: ObjectCard):
	for node in $Scroller_Object/Info_Object.get_children():
		node.hide()

	var info = _object_data[obj.database_id]
	$Scroller_Object/Info_Object/Name.text = info["info_name"]
	$Scroller_Object/Info_Object/Description.text = info["description"]

	$Scroller_Object/Info_Object/Name.show()
	$Scroller_Object/Info_Object/Separator_01.show()
	$Scroller_Object/Info_Object/Description.show()

	var case = GameState.get_current_case()

	var locations = case.find_links_to(obj, Link.Type.FOUND)
	if locations:
		$Scroller_Object/Info_Object/Separator_02.show()
		$Scroller_Object/Info_Object/Found.show()
		$Scroller_Object/Info_Object/Found_Location.text = locations[0].get_display_name()
		$Scroller_Object/Info_Object/Found_Location.show()

	var owners = case.find_links_to(obj, Link.Type.PROPERTY).filter(
		func(card): return card is NpcCard)
	if owners:
		$Scroller_Object/Info_Object/Separator_03.show()
		$Scroller_Object/Info_Object/Property.show()
		$Scroller_Object/Info_Object/Property_NPC.text = _make_card_list(owners)
		$Scroller_Object/Info_Object/Property_NPC.show()

	if obj.is_object_evidence:
		$Scroller_Object/Info_Object/Separator_04.show()
		$Scroller_Object/Info_Object/Evidence.show()

	$Scroller_Object.show()
	$Scroller_NPC.hide()
	$Scroller_Location.hide()

func show_npc(npc: NpcCard):
	for node in $Scroller_NPC/Info_NPC.get_children():
		node.hide()

	$Scroller_NPC/Info_NPC/NPC_Name.text = npc.get_display_name()
	$Scroller_NPC/Info_NPC/NPC.show()
	$Scroller_NPC/Info_NPC/NPC_Name.show()

	var health_label: Control

	match npc.npc_health:
		NpcCard.NpcHealth.GOOD:
			health_label = $Scroller_NPC/Info_NPC/Health_Good
		NpcCard.NpcHealth.AVERAGE:
			health_label = $Scroller_NPC/Info_NPC/Health_Average
		NpcCard.NpcHealth.LOW:
			health_label = $Scroller_NPC/Info_NPC/Health_Low

	if health_label:
		$Scroller_NPC/Info_NPC/Separator_01.show()
		$Scroller_NPC/Info_NPC/Health.show()
		health_label.show()

	var status_label: Control

	match npc.npc_status:
		NpcCard.NpcStatus.NONE:
			status_label = $Scroller_NPC/Info_NPC/Status_None
		NpcCard.NpcStatus.JAIL:
			status_label = $Scroller_NPC/Info_NPC/Status_In_Jail
		NpcCard.NpcStatus.DEAD:
			status_label = $Scroller_NPC/Info_NPC/Status_Dead
		NpcCard.NpcStatus.DISAPPEARED:
			status_label = $Scroller_NPC/Info_NPC/Status_Disappeared
		NpcCard.NpcStatus.MINION:
			status_label = $Scroller_NPC/Info_NPC/Status_Minion
		NpcCard.NpcStatus.VICTIM:
			status_label = $Scroller_NPC/Info_NPC/Status_Victim
		NpcCard.NpcStatus.SUSPECT:
			status_label = $Scroller_NPC/Info_NPC/Status_Suspect
		NpcCard.NpcStatus.WITNESS:
			status_label = $Scroller_NPC/Info_NPC/Status_Witness
		NpcCard.NpcStatus.CULPRIT:
			status_label = $Scroller_NPC/Info_NPC/Status_Culprit
		NpcCard.NpcStatus.ACCOMPLICE:
			status_label = $Scroller_NPC/Info_NPC/Status_Accomplice

	if status_label:
		$Scroller_NPC/Info_NPC/Separator_02.show()
		$Scroller_NPC/Info_NPC/Status.show()
		status_label.show()

	var case = GameState.get_current_case()

	if npc.is_married:
		var partners = case.find_links_to(npc, Link.Type.INTIMACY)
		if not partners.is_empty():
			$Scroller_NPC/Info_NPC/Separator_03.show()
			$Scroller_NPC/Info_NPC/Couple.show()
			$Scroller_NPC/Info_NPC/Couple_NPC.text = partners[0].get_display_name()
			$Scroller_NPC/Info_NPC/Couple_NPC.show()

	var friends = case.find_links_to(npc, Link.Type.FRIEND)
	if friends:
		$Scroller_NPC/Info_NPC/Separator_04.show()
		$Scroller_NPC/Info_NPC/Friends.show()
		$Scroller_NPC/Info_NPC/Friends_NPC_01.text = _make_card_list(friends)
		$Scroller_NPC/Info_NPC/Friends_NPC_01.show()

	var enemies = case.find_links_to(npc, Link.Type.ENEMY)
	if enemies:
		$Scroller_NPC/Info_NPC/Separator_05.show()
		$Scroller_NPC/Info_NPC/Enemies.show()
		$Scroller_NPC/Info_NPC/Enemies_NPC_01.text = _make_card_list(enemies)
		$Scroller_NPC/Info_NPC/Enemies_NPC_01.show()

	var acquaintances = case.find_links_to(npc, Link.Type.ACQUAINTANCE)
	if acquaintances:
		$Scroller_NPC/Info_NPC/Separator_06.show()
		$Scroller_NPC/Info_NPC/Acquaintance.show()
		$Scroller_NPC/Info_NPC/Acquaintance_NPC_01.text = _make_card_list(acquaintances)
		$Scroller_NPC/Info_NPC/Acquaintance_NPC_01.show()

	var affairs = case.find_links_to(npc, Link.Type.INTIMACY)
	if npc.is_married:
		affairs.pop_front()
	if affairs:
		$Scroller_NPC/Info_NPC/Separator_07.show()
		$Scroller_NPC/Info_NPC/Affair.show()
		$Scroller_NPC/Info_NPC/Affair_NPC.text = _make_card_list(affairs)
		$Scroller_NPC/Info_NPC/Affair_NPC.show()

	var debts = case.find_links_to(npc, Link.Type.DEBT)
	if debts:
		$Scroller_NPC/Info_NPC/Separator_08.show()
		$Scroller_NPC/Info_NPC/Debt_Influence.show()
		$Scroller_NPC/Info_NPC/Debt_Influence_NPC_01.text = _make_card_list(debts)
		$Scroller_NPC/Info_NPC/Debt_Influence_NPC_01.show()

	var ideology = case.find_links_to(npc, Link.Type.IDEOLOGY)
	if ideology:
		$Scroller_NPC/Info_NPC/Separator_09.show()
		$Scroller_NPC/Info_NPC/Ideology.show()
		$Scroller_NPC/Info_NPC/Ideology_NPC_01.text = _make_card_list(ideology)
		$Scroller_NPC/Info_NPC/Ideology_NPC_01.show()

	var home = case.find_links_to(npc, Link.Type.HOME)
	if home:
		$Scroller_NPC/Info_NPC/Separator_12.show()
		$Scroller_NPC/Info_NPC/Home.show()
		$Scroller_NPC/Info_NPC/Home_Location.text = home[0].get_display_name()
		$Scroller_NPC/Info_NPC/Home_Location.show()

	var work = case.find_links_to(npc, Link.Type.WORK)
	if work:
		$Scroller_NPC/Info_NPC/Separator_13.show()
		$Scroller_NPC/Info_NPC/Work.show()
		$Scroller_NPC/Info_NPC/Work_Location.text = work[0].get_display_name()
		$Scroller_NPC/Info_NPC/Work_Location.show()

	var hangout = case.find_links_to(npc, Link.Type.HANGOUT)
	if hangout:
		$Scroller_NPC/Info_NPC/Separator_14.show()
		$Scroller_NPC/Info_NPC/Hangout.show()
		$Scroller_NPC/Info_NPC/Hangout_Location.text = hangout[0].get_display_name()
		$Scroller_NPC/Info_NPC/Hangout_Location.show()

	var hideout = case.find_links_to(npc, Link.Type.HIDEOUT)
	if hideout:
		$Scroller_NPC/Info_NPC/Separator_15.show()
		$Scroller_NPC/Info_NPC/Hideout.show()
		$Scroller_NPC/Info_NPC/Hideout_Location.text = hideout[0].get_display_name()
		$Scroller_NPC/Info_NPC/Hideout_Location.show()

	var property = case.find_links_to(npc, Link.Type.PROPERTY)
	if property:
		var text = ""
		for obj in property:
			if not text.is_empty():
				text += "\n"
			text += obj.get_display_name()
			if obj.is_object_evidence:
				text += " (evidence)"
		$Scroller_NPC/Info_NPC/Separator_16.show()
		$Scroller_NPC/Info_NPC/Properties.show()
		$Scroller_NPC/Info_NPC/Properties_Object.text = _make_card_list(property)
		$Scroller_NPC/Info_NPC/Properties_Object.show()

	$Scroller_Object.hide()
	$Scroller_NPC.show()
	$Scroller_Location.hide()

func _make_card_list(cards: Array[BaseCard]) -> String:
	var text = ""
	for card in cards:
		if not text.is_empty():
			text += "\n"
		text += card.get_display_name()
	return text
