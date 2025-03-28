extends Control


func reset_all_buttons():
	for child in get_children():
		if child is Button or TextureButton:
			child.button_pressed = false
			# Exemples :
			$"../../TMP_1/Main_Playmat/Links/Link_Pointillé_Blanc".modulate.a = 1.0
			$"../../TMP_1/Main_Playmat/Links/Link_Plein_Jaune".modulate.a = 1.0

func _on_any_button_mouse_entered():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()

func _on_any_button_mouse_exited():
	if $"../../Shared_Interface_Sounds/Hover".playing == true or $"../../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()

func _on_legend_pressed():
	$"../../Shared_Interface_Sounds/Cancel".play()
	reset_all_buttons()

func _on_validation_yellow_toggled(toggled_on: bool):
	if toggled_on == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Plein_Jaune".modulate.a = 0.333
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Plein_Jaune".modulate.a = 1.0

func _on_hideout_white_toggled(toggled_on: bool):
	if toggled_on == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Pointillé_Blanc".modulate.a = 0.333
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Pointillé_Blanc".modulate.a = 1.0

func _on_any_button_toggled(toggled_on: bool):
	if toggled_on == true:
		$"../../Shared_Interface_Sounds/Valid".play()
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()

func _on_new_dark_purple_toggled(toggled_on: bool):
	if toggled_on == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Violet_Rose".modulate.a = 0.333
		$"../../TMP_1/Main_Playmat/Links/TEST_LINK/Link_1/Papa_Link".modulate.a = 0.333
		
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Violet_Rose".modulate.a = 1.0
		$"../../TMP_1/Main_Playmat/Links/TEST_LINK/Link_1/Papa_Link".modulate.a = 1.0
		$Intimacy_Pink.button_pressed = false
		$Property_Light_Green.button_pressed = false

func _on_intimacy_pink_toggled(toggled_on: bool):
	if toggled_on == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Violet_Rose".modulate.a = 0.333
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()
		$"../../TMP_1/Main_Playmat/Links/Link_Violet_Rose".modulate.a = 1.0
		$New_Dark_Purple.button_pressed = false

func _on_acquaintance_light_blue_toggled(toggled_on: bool):
	if toggled_on == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		$"../../TMP_1/Main_Playmat/Links/TEST_LINK/Link_2/Papa_Link".modulate.a = 0.333
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()
		$"../../TMP_1/Main_Playmat/Links/TEST_LINK/Link_2/Papa_Link".modulate.a = 1.0

func _on_property_light_green_toggled(toggled_on: bool):
	if toggled_on == true:
		$"../../Shared_Interface_Sounds/Valid".play()
		$"../../TMP_1/Main_Playmat/Links/TEST_LINK/Link_1/Papa_Link".modulate.a = 0.333
	else:
		$"../../Shared_Interface_Sounds/Cancel".play()
		$"../../TMP_1/Main_Playmat/Links/TEST_LINK/Link_1/Papa_Link".modulate.a = 1.0
		$New_Dark_Purple.button_pressed = false
