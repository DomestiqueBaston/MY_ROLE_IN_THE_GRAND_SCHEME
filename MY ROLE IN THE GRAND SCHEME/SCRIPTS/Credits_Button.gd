extends Control


func _on_ok_pressed():
	$"../Shared_Interface_Sounds/Valid".play()
	await $"../Shared_Interface_Sounds/Valid".finished

func _on_ok_mouse_entered():
	if $"../Shared_Interface_Sounds/Leave".playing == true or $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Hover".play()

func _on_ok_mouse_exited():
	if $"../Shared_Interface_Sounds/Hover".playing == true or $"../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Leave".play()
