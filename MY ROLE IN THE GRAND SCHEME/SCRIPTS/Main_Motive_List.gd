extends MenuButton

@export var initial_text: String = "Select a crime motive..."
@export var initial_tooltip: String = "Which word are you struggling with?"
@export var alert_player: AnimationPlayer

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data
var _final_crime_data = preload("res://JSON/CASE/Final_Crime_Motive_Evidence.json").data
var _current_crime_data

# At any given time, _current_crime_data points to either _crime_data, for
# normal cases, or to _final_crime_data, for the "final" case, when the user is
# paranoid. There is an important difference between the two JSON files: normal
# cases have several possible motives for each crime, each with one name; the
# final case has only one crime and one motive, but that motive has several
# names. So it has a "names" property, rather than a "name" property. Those
# names are displayed in the menu here, but cannot be used to solve the case.
# And, for the final case, Case.selected_motive is set to the name that the
# player has chosen from the menu, rather than the ID of the motive, which is
# always the same and is of no importance.

func _ready():

	# populate the menu initially for a normal case or, if the player has
	# attained paranoia, for the final case

	if GameState.player.is_paranoid():
		_current_crime_data = _final_crime_data
	else:
		_current_crime_data = _crime_data
		GameState.paranoia.connect(_on_paranoia)

	_populate()

	# when the menu is popped up, disable menu items for motives that are not
	# compatible with the current case

	get_popup().about_to_popup.connect(_enable_disable_motives)

#
# Called when the player has suffered an attack of paranoia to repopulate the
# menu. Note that this is never called if the player is already paranoid when
# the scene is loaded; there is no coming back from paranoia...
#
func _on_paranoia():
	if _current_crime_data != _final_crime_data:
		_current_crime_data = _final_crime_data
		_populate()

func _populate():
	# (re)populate the popup menu

	var popup: PopupMenu = get_popup()
	popup.clear(true)

	var crime_index = 0
	for crime in _current_crime_data:
		var crime_dict = _current_crime_data[crime]
		var submenu: PopupMenu = PopupMenu.new()
		for motive_id in crime_dict:
			var motive_dict = crime_dict[motive_id]
			if _current_crime_data == _final_crime_data:
				for motive in motive_dict.names:
					submenu.add_item(_get_label(motive))
			else:
				submenu.add_item(_get_label(motive_dict.name))
		popup.add_submenu_node_item(_get_label(crime), submenu)
		submenu.index_pressed.connect(_on_item_pressed.bind(crime_index))
		crime_index += 1

	# if a crime and motive have been selected, highlight them in the menu, and
	# set the menu button's label and tooltip accordingly

	_update_selected_motive()

##
## Unselects all motives in the menu except the one that has been selected for
## the current case, and sets the menu button's label and tooltip accordingly.
## Call this if the current case has changed, or if its selected motive has
## (but normally that is only done here: see _on_item_pressed()).
##
func update():
	# unselect all motives

	var popup: PopupMenu = get_popup()
	var crime_index = 0
	for crime in _current_crime_data:
		var crime_dict = _current_crime_data[crime]
		popup.set_item_text(crime_index, _get_label(crime))
		var submenu: PopupMenu = popup.get_item_submenu_node(crime_index)
		var motive_index = 0
		for motive_id in crime_dict:
			var motive_dict = crime_dict[motive_id]
			if _current_crime_data == _final_crime_data:
				var motives = motive_dict.names
				for i in motives.size():
					submenu.set_item_text(i, _get_label(motives[i]))
			else:
				submenu.set_item_text(motive_index, _get_label(motive_dict.name))
			motive_index += 1
		crime_index += 1

	# select the current motive, if there is one, and update the button text
	# and tooltip

	_update_selected_motive()

#
# If a crime and motive have been selected for the current case, select the
# corresponding item in the menu, and update the menu button's text and tooltip
# accordingly.
#
func _update_selected_motive():
	var case: Case = GameState.get_current_case()
	if case and case.selected_crime and case.selected_motive:
		if _current_crime_data == _final_crime_data:
			text = case.selected_motive
		else:
			text = _crime_data[case.selected_crime][case.selected_motive].name
		tooltip_text = case.selected_crime
		_set_motive_checked(case.selected_crime, case.selected_motive, true)
	else:
		text = initial_text
		tooltip_text = initial_tooltip

#
# Callback invoked when the user selects a motive from the menu.
#
func _on_item_pressed(motive_index: int, crime_index: int):
	# update the menu's label and tooltip

	var crime = _current_crime_data.keys()[crime_index]
	var crime_dict = _current_crime_data[crime]
	var selected_motive: String

	if _current_crime_data == _final_crime_data:
		var motive_id = crime_dict.keys().front()
		text = crime_dict[motive_id].names[motive_index]
		selected_motive = text
	else:
		var motive_id = crime_dict.keys()[motive_index]
		text = crime_dict[motive_id].name
		selected_motive = motive_id

	tooltip_text = crime

	# unhighlight the previous motive and highlight the new one

	var case: Case = GameState.get_current_case()
	if case:
		if case.selected_crime and case.selected_motive:
			_set_motive_checked(case.selected_crime, case.selected_motive, false)
		case.selected_crime = crime
		case.selected_motive = selected_motive
		_set_motive_checked(case.selected_crime, case.selected_motive, true)

#
# Highlights or unhighlights the given crime and motive in the menu.
#
func _set_motive_checked(crime: String, motive_id: String, checked: bool):
	var submenu_index = _current_crime_data.keys().find(crime)
	if submenu_index >= 0:
		var popup: PopupMenu = get_popup()
		popup.set_item_text(submenu_index, _get_label(crime, checked))
		var submenu: PopupMenu = popup.get_item_submenu_node(submenu_index)
		var crime_dict = _current_crime_data[crime]
		var motive_index: int
		var motive_name: String
		if _current_crime_data == _final_crime_data:
			var id = crime_dict.keys().front()
			motive_index = crime_dict[id].names.find(motive_id)
			if motive_index >= 0:
				motive_name = motive_id
		else:
			motive_index = crime_dict.keys().find(motive_id)
			if motive_index >= 0:
				motive_name = crime_dict[motive_id].name
		if motive_name:
			submenu.set_item_text(motive_index, _get_label(motive_name, checked))

func _get_label(base_name: String, checked: bool = false) -> String:
	return (">" if checked else " ") + base_name

func _get_npcs_of_interest(
	case: Case, victims: Array[NpcCard], culprits: Array[NpcCard], accomplices: Array[NpcCard]):
	for npc in case.npcs:
		match npc.apparent_role:
			NpcCard.NpcRole.VICTIM:
				victims.append(npc)
			NpcCard.NpcRole.CULPRIT:
				culprits.append(npc)
			NpcCard.NpcRole.ACCOMPLICE:
				accomplices.append(npc)

#
# Enables/disables motives depending on whether they are applicable to the
# current case.
#
func _enable_disable_motives():
	# in the final case, all motives are valid (and useless)
	if _current_crime_data == _final_crime_data:
		return

	if alert_player:
		alert_player.play("RESET")

	var popup: PopupMenu = get_popup()

	var case = GameState.get_current_case()
	if case == null:
		for crime_index in _current_crime_data.size():
			popup.set_item_disabled(crime_index, true)
		return

	# fetch victims and count identified culprits and accomplices once and for
	# all

	var victims: Array[NpcCard]
	var culprits: Array[NpcCard]
	var accomplices: Array[NpcCard]
	_get_npcs_of_interest(case, victims, culprits, accomplices)

	# iterate over the crime submenus and motive entries

	var crime_index = 0

	for crime in _current_crime_data:
		var crime_dict = _current_crime_data[crime]
		var submenu: PopupMenu = popup.get_item_submenu_node(crime_index)
		var motive_index = 0
		var is_one_enabled = false
		for motive_id in crime_dict:
			var is_enabled = _is_motive_valid(
				crime_dict[motive_id], case, victims, culprits, accomplices)
			submenu.set_item_disabled(motive_index, not is_enabled)
			is_one_enabled = is_one_enabled or is_enabled
			motive_index += 1
		popup.set_item_disabled(crime_index, not is_one_enabled)
		crime_index += 1

func _is_motive_valid(
	motive_dict: Dictionary, case: Case, victims: Array[NpcCard],
	culprits: Array[NpcCard], accomplices: Array[NpcCard]) -> bool:

	#  no case, or the "final" case => all motives are valid
	if case == null or _current_crime_data == _final_crime_data:
		return true

	# is there a crime scene?

	var location_names = motive_dict.crime_location
	if location_names == ["none"]:
		if case.get_crime_location():
			return false
	else:
		if not case.get_crime_location():
			return false

	# do the victim, culprit and accomplice counts correspond?

	if case.get_victim_count() as float not in motive_dict.victims:
		return false
	if culprits.size() > motive_dict.culprits.back():
		return false
	if accomplices.size() > motive_dict.accomplices.back():
		return false

	# is the number of deaths compatible?

	match motive_dict.dead_victims:
		"no":
			if case.get_dead_victim_count() > 0:
				return false
		"yes":
			if case.get_dead_victim_count() == 0:
				return false

	# for cases of adultery, there must be a married victim

	if motive_dict.get("is_adultery", false):
		var married_victim = false
		for victim in victims:
			if victim.is_married:
				married_victim = true
				break
		if not married_victim:
			return false

	# exclude motives that cannot include an incriminating link identified by
	# the player

	if culprits or accomplices:
		var motive_links = motive_dict["link"]
		for victim in victims:
			for link in victim.find_links():
				var other = link.pin2.backing if link.pin1.backing == victim else link.pin1.backing
				if not other is NpcCard or not (other in culprits or other in accomplices):
					continue
				match link.type:
					Link.Type.DEBT:
						if not "debt_influence" in motive_links:
							return false
					Link.Type.INTIMACY:
						if not "intimacy" in motive_links:
							return false
					Link.Type.FRIEND:
						if not ("friend" in motive_links or
								"enemy/friend" in motive_links):
							return false
					Link.Type.ENEMY:
						if not ("enemy" in motive_links or
								"enemy/friend" in motive_links):
							return false
					Link.Type.ACQUAINTANCE:
						if not "acquaintance" in motive_links:
							return false
					Link.Type.IDEOLOGY:
						if not "ideology" in motive_links:
							return false

	return true

##
## Checks whether the currently selected motive is still applicable to the
## current case. If it is not, the motive is cleared and a warning animation is
## played; the animation is reset the next time the popup menu is displayed or
## this function is called.
##
func check_motive_validity():
	# in the final case, motives serve no purpose
	if _current_crime_data == _final_crime_data:
		return

	var case = GameState.get_current_case()
	if not (case and case.selected_crime and case.selected_motive):
		if alert_player:
			alert_player.play("RESET")
		return

	var victims: Array[NpcCard]
	var culprits: Array[NpcCard]
	var accomplices: Array[NpcCard]
	_get_npcs_of_interest(case, victims, culprits, accomplices)

	if not _is_motive_valid(
		_current_crime_data[case.selected_crime][case.selected_motive], case, victims,
		culprits, accomplices):
		_set_motive_checked(case.selected_crime, case.selected_motive, false)
		case.selected_crime = ""
		case.selected_motive = ""
		text = initial_text
		tooltip_text = initial_tooltip
		if alert_player:
			alert_player.play("Alert")
