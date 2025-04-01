extends OptionButton

var description_array = []
var max_text_length = 37

func _ready():
	get_popup().max_size.y = 134
	get_popup().min_size.x = 191
	
	var file = FileAccess.open("res://JSON/CASE/Crime_Motive_Evidence.json", FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()
	
	var motives = JSON.new()
	var _parse_result = motives.parse(json_data)
	var data = motives.get_data()
	
	clear()

	for crime_entry in data:
		if "motive" in crime_entry and crime_entry["motive"] is Array:
			for item in crime_entry["motive"]:
				if "name" in item:
					var truncated_name = truncate_text(item["name"])
					add_item(truncated_name)
					description_array.append(item["name"])

					# Les tooltips ne s'affichent plus dès que l'on scroll la liste
					set_item_tooltip(get_item_count() - 1, item["name"])

	if get_item_count() > 0:
		add_separator("Select a motive")
		self.selected = get_item_count() - 1
		

func truncate_text(original_text: String) -> String:
	if original_text.length() > max_text_length:
		return original_text.substr(0, max_text_length - 3) + "..."
	return original_text
