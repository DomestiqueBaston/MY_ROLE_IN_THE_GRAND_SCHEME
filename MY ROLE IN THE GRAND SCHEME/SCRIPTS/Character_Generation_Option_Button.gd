extends OptionButton

var _backgrounds = preload("res://JSON/PLAYER/Background_Descriptions.json").data

signal background_selected

func _ready():
	var popup = get_popup()
	popup.transparent = true
	popup.max_size = Vector2(162, 101)

	if _backgrounds is Array and _backgrounds.size() > 0:
		for item in _backgrounds:
			add_item(item["profession"])
		add_separator("Select a background")
		selected = item_count - 1

func reset():
	selected = item_count - 1
	background_selected.emit()

func randomize():
	selected = randi_range(0, _backgrounds.size() - 1)
	background_selected.emit()

func _on_item_selected(_index: int):
	background_selected.emit()

func _on_button_down():
	Globals.hover_sound.play()

func _on_button_up():
	Globals.leave_sound.play()

func get_background() -> Dictionary:
	if selected >= 0 and selected < _backgrounds.size():
		return _backgrounds[selected]
	else:
		return {}

func get_background_story() -> String:
	if selected >= 0 and selected < _backgrounds.size():
		return _backgrounds[selected]["description"]
	else:
		return ""
