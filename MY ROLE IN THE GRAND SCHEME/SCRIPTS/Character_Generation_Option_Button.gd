extends MenuButton

signal background_selected

var _backgrounds = preload("res://JSON/PLAYER/Background_Descriptions.json").data
var _selected: int

func _ready():
	var popup = get_popup()

	if _backgrounds is Array and _backgrounds.size() > 0:
		for item in _backgrounds:
			popup.add_item(item["profession"])

	popup.index_pressed.connect(_on_item_selected)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	reset()

func reset():
	_selected = -1
	text = "Select a background"
	background_selected.emit()

func randomize():
	_on_item_selected(randi() % _backgrounds.size())

func _on_item_selected(index: int):
	_selected = index
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
