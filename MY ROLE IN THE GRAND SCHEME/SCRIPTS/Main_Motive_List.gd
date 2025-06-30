extends OptionButton

var description_array = []
var max_text_length = 51

func _ready():
	get_popup().max_size.y = 307
	get_popup().min_size.x = 184
	get_popup().max_size.x = 249
	
	var file = FileAccess.open("res://JSON/CASE/Crime_Motive_Evidence.json", FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()
	
	var motives = JSON.new()
	var _parse_result = motives.parse(json_data)
	var data = motives.get_data()
	
	clear()
	
	add_separator("Select a crime motive...")

	for crime_entry in data:
		if "crime" in crime_entry and "motive" in crime_entry and crime_entry["motive"] is Array:
			
			add_separator(crime_entry["crime"])
			
			for item in crime_entry["motive"]:
				if "name" in item:
					var truncated_name = truncate_text(item["name"])
					add_item(truncated_name)
					description_array.append(item["name"])

					set_item_tooltip(get_item_count() - 1, item["name"]) # Une fois la liste scrollée, les tooltips ne s'affichent plus. C'est un problème...

	
	self.selected = 0 #get_item_count() - 1
	
	make_first_separator_invisible()


func truncate_text(original_text: String) -> String:
	if original_text.length() > max_text_length:
		return original_text.substr(0, max_text_length - 2) + "..."
	return original_text


func make_first_separator_invisible():
	var popup = get_popup()
	if popup:
		var separator_index = 0 #get_item_count() - 1
		popup.set_item_text(separator_index, " ")
