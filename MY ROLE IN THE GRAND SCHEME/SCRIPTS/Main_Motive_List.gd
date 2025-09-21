extends MenuButton

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

func _ready():
	var popup: PopupMenu = get_popup()
	for crime in _crime_data:
		var submenu: PopupMenu = PopupMenu.new()
		for motive in _crime_data[crime]:
			submenu.add_item(motive["name"])
		popup.add_submenu_node_item(crime, submenu)
		submenu.index_pressed.connect(_on_item_pressed.bind(submenu, crime))

func _on_item_pressed(idx: int, submenu: PopupMenu, crime: String):
	text = submenu.get_item_text(idx)
	tooltip_text = crime
