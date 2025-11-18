extends MenuButton

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

func _ready():
	var popup: PopupMenu = get_popup()
	for crime in _crime_data:
		var crime_dict = _crime_data[crime]
		var submenu: PopupMenu = PopupMenu.new()
		for motive in crime_dict:
			var motive_dict = crime_dict[motive]
			submenu.add_check_item(motive_dict.name)
			submenu.set_item_metadata(submenu.item_count - 1, motive)
		popup.add_submenu_node_item(_get_submenu_name(crime, false), submenu)
		submenu.index_pressed.connect(_on_item_pressed.bind(submenu, crime))

	var case: Case = GameState.get_current_case()
	if case:
		var current_crime = case.selected_crime
		var current_motive = case.selected_motive
		if current_crime and current_motive:
			text = _crime_data[current_crime][current_motive].name
			tooltip_text = current_crime
			_set_motive_checked(current_crime, current_motive, true)

func _on_item_pressed(idx: int, submenu: PopupMenu, crime: String):
	text = submenu.get_item_text(idx)
	tooltip_text = crime

	var case: Case = GameState.get_current_case()
	if case:
		if case.selected_crime and case.selected_motive:
			_set_motive_checked(case.selected_crime, case.selected_motive, false)
		case.selected_crime = crime
		case.selected_motive = submenu.get_item_metadata(idx)
		if case.selected_crime and case.selected_motive:
			_set_motive_checked(case.selected_crime, case.selected_motive, true)

func _set_motive_checked(crime: String, motive: String, checked: bool):
	var popup: PopupMenu = get_popup()
	var submenu_index = _crime_data.keys().find(crime)
	if submenu_index >= 0:
		popup.set_item_text(submenu_index, _get_submenu_name(crime, checked))
		var submenu: PopupMenu = popup.get_item_submenu_node(submenu_index)
		var motive_index = _crime_data[crime].keys().find(motive)
		if motive_index >= 0:
			submenu.set_item_checked(motive_index, checked)

func _get_submenu_name(crime: String, checked: bool) -> String:
	return (">" if checked else " ") + crime
