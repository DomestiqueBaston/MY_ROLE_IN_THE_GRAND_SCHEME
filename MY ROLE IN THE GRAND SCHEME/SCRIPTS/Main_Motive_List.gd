extends MenuButton

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

func _ready():
	# populate the popup menu

	var popup: PopupMenu = get_popup()
	var crime_index = 0
	for crime in _crime_data:
		var crime_dict = _crime_data[crime]
		var submenu: PopupMenu = PopupMenu.new()
		for motive_id in crime_dict:
			var motive_dict = crime_dict[motive_id]
			submenu.add_item(_get_label(motive_dict.name))
		popup.add_submenu_node_item(_get_label(crime), submenu)
		submenu.index_pressed.connect(_on_item_pressed.bind(crime_index))
		crime_index += 1

	# disable menu items for motives that are not valid for the current case
	# when the menu is popped up

	popup.about_to_popup.connect(_enable_disable_motives)

	# if a crime and motive have been selected, highlight them in the menu, and
	# set the menu's label and tooltip accordingly

	var case: Case = GameState.get_current_case()
	if case and case.selected_crime and case.selected_motive:
		text = _crime_data[case.selected_crime][case.selected_motive].name
		tooltip_text = case.selected_crime
		_set_motive_checked(case.selected_crime, case.selected_motive, true)

#
# Callback invoked when the user selects a motive from the menu.
#
func _on_item_pressed(motive_index: int, crime_index: int):
	# update the menu's label and tooltip

	var crime = _crime_data.keys()[crime_index]
	var crime_dict = _crime_data[crime]
	var motive_id = crime_dict.keys()[motive_index]
	text = crime_dict[motive_id].name
	tooltip_text = crime

	# unhighlight the previous motive and highlight the new one

	var case: Case = GameState.get_current_case()
	if case:
		if case.selected_crime and case.selected_motive:
			_set_motive_checked(case.selected_crime, case.selected_motive, false)
		case.selected_crime = crime
		case.selected_motive = motive_id
		_set_motive_checked(case.selected_crime, case.selected_motive, true)

#
# Highlights or unhighlights the given crime and motive in the menu.
#
func _set_motive_checked(crime: String, motive_id: String, checked: bool):
	var submenu_index = _crime_data.keys().find(crime)
	if submenu_index >= 0:
		var popup: PopupMenu = get_popup()
		popup.set_item_text(submenu_index, _get_label(crime, checked))
		var submenu: PopupMenu = popup.get_item_submenu_node(submenu_index)
		var crime_dict = _crime_data[crime]
		var motive_index = crime_dict.keys().find(motive_id)
		if motive_index >= 0:
			var motive_name = crime_dict[motive_id].name
			submenu.set_item_text(motive_index, _get_label(motive_name, checked))

func _get_label(base_name: String, checked: bool = false) -> String:
	return (">" if checked else " ") + base_name

#
# Enables/disables motives depending on whether they are applicable to the
# current case.
#
func _enable_disable_motives():
	var case = GameState.get_current_case()

	# count identified culprits and accomplices once and for all

	var culprit_count = 0
	var accomplice_count = 0

	for npc in case.npcs:
		match npc.apparent_role:
			NpcCard.NpcRole.CULPRIT:
				culprit_count += 1
			NpcCard.NpcRole.ACCOMPLICE:
				accomplice_count += 1

	# iterate over the crime submenus and motive entries

	var popup: PopupMenu = get_popup()
	var crime_index = 0

	for crime in _crime_data:
		var crime_dict = _crime_data[crime]
		var submenu: PopupMenu = popup.get_item_submenu_node(crime_index)
		var motive_index = 0
		var is_one_enabled = false
		for motive_id in crime_dict:
			var is_enabled = _is_motive_valid(
				crime_dict[motive_id], case, culprit_count, accomplice_count)
			submenu.set_item_disabled(motive_index, not is_enabled)
			is_one_enabled = is_one_enabled or is_enabled
			motive_index += 1
		popup.set_item_disabled(crime_index, not is_one_enabled)
		crime_index += 1

func _is_motive_valid(
	motive_dict: Dictionary, case: Case, culprit_count: int,
	accomplice_count: int) -> bool:

	if case == null:
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
	if culprit_count > motive_dict.culprits.back():
		return false
	if accomplice_count > motive_dict.accomplices.back():
		return false

	# is the number of deaths compatible?

	match motive_dict.dead_victims:
		"no":
			if case.get_dead_victim_count() > 0:
				return false
		"yes":
			if case.get_dead_victim_count() == 0:
				return false

	return true
