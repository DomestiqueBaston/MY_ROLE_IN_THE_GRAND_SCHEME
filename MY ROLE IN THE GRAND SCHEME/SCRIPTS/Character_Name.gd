extends LineEdit

@export var max_width_px: float = 72.0

var font: Font = null
var font_size: int = 0

func _ready():
	font = get_theme_font("font")
	font_size = get_theme_font_size("font_size")

func _on_text_changed(new_text: String) -> void:
	# Calcule la largeur du texte en pixels
	var text_width = font.get_string_size(new_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	if text_width > max_width_px:
		# Supprime le dernier caractère si ça dépasse !
		text = new_text.substr(0, new_text.length() - 1)
