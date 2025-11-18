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
