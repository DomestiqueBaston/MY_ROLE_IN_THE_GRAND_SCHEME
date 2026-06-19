extends VSlider

# The actual difficulty level is determined by Globals.game_difficulty; make
# sure that its value and its default value are consistent with the number of
# levels/tooltips.

const _tooltips = [
	"For dummies...",
	"No sweat, no tears",
	"Business as usual",
	"No holds barred",
	"Nightmare fueled!"
]

func _ready():
	min_value = 0
	max_value = _tooltips.size() - 1
	rounded = true
	value = roundf(max_value / 2)
	_on_value_changed(value)

func _on_value_changed(new_value: float):
	tooltip_text = "Difficulty: " + _tooltips[int(new_value)]
