extends MenuButton

signal background_selected

var _backgrounds = preload("res://JSON/PLAYER/Background_Descriptions.json").data
var _selected: int

func _ready():
	if _backgrounds is Array:
		var popup = get_popup()
		var submenus = {}
		for id in _backgrounds.size():
			var item = _backgrounds[id]
			var category = item.category
			var profession = item.profession
			var submenu: PopupMenu
			if category in submenus:
				submenu = submenus[category]
			else:
				submenu = PopupMenu.new()
				popup.add_submenu_node_item(category, submenu)
				submenu.id_pressed.connect(_on_item_selected)
				submenus[category] = submenu
			submenu.add_item(profession, id)

	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	reset()

func reset():
	_selected = -1
	text = "Select a background"
	background_selected.emit()

func randomize():
	_on_item_selected(randi() % _backgrounds.size())

func _on_item_selected(id: int):
	_selected = id
	text = _backgrounds[_selected].profession
	background_selected.emit()

func _on_button_down():
	Globals.hover_sound.play()

func _on_button_up():
	Globals.leave_sound.play()

func get_background() -> Dictionary:
	if _selected >= 0 and _selected < _backgrounds.size():
		return _backgrounds[_selected]
	else:
		return {}

func get_background_story() -> String:
	if _selected >= 0 and _selected < _backgrounds.size():
		return _backgrounds[_selected].description
	else:
		return ""
