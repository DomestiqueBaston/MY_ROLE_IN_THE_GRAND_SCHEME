extends Control



func _on_bring_it_on_pressed():
	$"../Shared_Interface_Sounds/Valid".play()

func _on_bring_it_on_mouse_entered():
	if $"../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Hover".play()

func _on_bring_it_on_mouse_exited():
	if $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Leave".play()
