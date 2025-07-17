extends Node2D

var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data

func show_location(loc: GameState.PlayerLocation, card: LocationCard = null):
	for node in $Scroller_Location/Info_Location.get_children():
		node.hide()

	var loc_name = ""
	var loc_desc = ""

	match loc:
		GameState.PlayerLocation.OFFICE:
			loc_name = "- AT THE OFFICE -"
			loc_desc = "Chaos reigns here, the files are trying to escape, and your sanity’s the only thing more disorganized than the paperwork."
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

	$Scroller_Object.hide()
	$Scroller_NPC.hide()
	$Scroller_Location.show()
