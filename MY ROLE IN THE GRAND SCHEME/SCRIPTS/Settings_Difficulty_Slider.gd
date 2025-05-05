extends VSlider

@onready var slider = self

func _ready():
	_update_tooltip(int(value))

func _on_value_changed(new_value):
	_update_tooltip(int(new_value))

func _update_tooltip(new_value: int):
	var labels = {
		1: "For dummies...",
		2: "No Sweat, no tears",
		3: "Business as usual",
		4: "No holds barred",
		5: "Nightmare fueled!"
	}

	tooltip_text = "Difficulty: " + labels.get(new_value, "")
