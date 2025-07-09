extends OptionButton

var _crime_data = preload("res://JSON/CASE/Crime_Motive_Evidence.json").data

func _ready():
	var popup = get_popup()
	popup.max_size.y = 307
	popup.min_size.x = 184
	popup.max_size.x = 249

	var item_index = 0
	add_separator("Select a crime motive...")
	item_index += 1

	for crime in _crime_data:
		add_separator(crime)
		item_index += 1

		var motive_index = 0
		for motive in _crime_data[crime]:
			add_item(motive["name"])
			var metadata = {
				"crime": crime,
				"motive_index": motive_index
			}
			set_item_metadata(item_index, metadata)
			item_index += 1
			motive_index += 1

	self.selected = 0
	popup.set_item_text(0, "")
	
	popup.index_pressed.connect(_on_item_pressed)

func _on_item_pressed(idx: int):
	var metadata = get_item_metadata(idx)
	var crime = metadata["crime"]
	var motive_index = metadata["motive_index"]
	var motive = _crime_data[crime][motive_index]
	tooltip_text = motive["name"]
