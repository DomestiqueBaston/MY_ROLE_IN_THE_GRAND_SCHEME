extends OptionButton

var _crimes = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

func _ready():
	var popup = get_popup()
	popup.max_size.y = 307
	popup.min_size.x = 184
	popup.max_size.x = 249

	var item_index = 0
	add_separator("Select a crime motive...")
	item_index += 1

	var crime_index = 0
	for crime_entry in _crimes:
		add_separator(crime_entry["crime"])
		item_index += 1

		var motive_index = 0
		for motive in crime_entry["motive"]:
			add_item(motive["name"])
			var metadata = {
				"crime_index": crime_index,
				"motive_index": motive_index
			}
			set_item_metadata(item_index, metadata)
			item_index += 1
			motive_index += 1

		crime_index += 1

	self.selected = 0
	popup.set_item_text(0, "")
	
	popup.index_pressed.connect(_on_item_pressed)

func _on_item_pressed(idx: int):
	var metadata = get_item_metadata(idx)
	var crime_index = metadata["crime_index"]
	var motive_index = metadata["motive_index"]
	var crime_dict = _crimes[crime_index]
	var motive_dict = crime_dict["motive"][motive_index]
	tooltip_text = motive_dict["name"]
