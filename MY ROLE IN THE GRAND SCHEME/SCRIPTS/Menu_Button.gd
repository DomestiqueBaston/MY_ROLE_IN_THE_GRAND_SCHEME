extends MenuButton

func _ready():
	var popup = get_popup()

	if not popup.is_connected("id_pressed", Callable(self, "_on_popup_item_selected")):
		popup.connect("id_pressed", Callable(self, "_on_popup_item_selected"))


# Je n'arrive pas à avoir de son au survol à la souris des items du PopupMenu (ou alors à la navigation au clavier). Uniquement à la sélection. Du coup, je vire...

func _on_popup_item_selected(_id):
	Globals.valid_sound.play()

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.leave_sound.play()

func _on_pressed():
	Globals.valid_sound.play()
