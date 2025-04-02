extends Control


# Un truc est chiant : il faudrait que le slider ne soit sélectionné pour le déplacer
# que lorsque l'on clique sur le grabber, pas dans le grabber area (ce qui est le cas actuellement).

func _on_mouse_entered():
	if $"../Shared_Interface_Sounds/Leave".playing == true or $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../Shared_Interface_Sounds/Leave".playing == true or $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Leave".play()

func _on_cancel_pressed():
	$"../Shared_Interface_Sounds/Cancel".play()

func _on_ok_pressed():
	$"../Shared_Interface_Sounds/Valid".play()

func _on_any_blue_button_pressed():
	$"../Shared_Interface_Sounds/Valid".play()
