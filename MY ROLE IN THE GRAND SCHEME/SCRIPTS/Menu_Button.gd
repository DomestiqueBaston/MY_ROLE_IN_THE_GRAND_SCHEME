extends MenuButton

func _ready():
	var popup = get_popup()

	if not popup.is_connected("id_pressed", Callable(self, "_on_popup_item_selected")):
		popup.connect("id_pressed", Callable(self, "_on_popup_item_selected"))


# Je n'arrive pas à avoir de son au survol à la souris des items du PopupMenu (ou alors à la navigation au clavier). Uniquement à la sélection. Du coup, je vire...

func _on_popup_item_selected(_id):
	$"../../Shared_Interface_Sounds/Valid".play()

func _on_mouse_entered():
	if $"../../Shared_Interface_Sounds/Leave".playing or $"../../Shared_Interface_Sounds/Hover".playing:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../../Shared_Interface_Sounds/Leave".playing or $"../../Shared_Interface_Sounds/Hover".playing:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()

func _on_pressed():
	$"../../Shared_Interface_Sounds/Valid".play()
