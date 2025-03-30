extends Button


func _on_pressed():
	$"../../Shared_Interface_Sounds/Cancel".play()
	await $"../../Shared_Interface_Sounds/Cancel".finished


func _on_mouse_entered():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()


func _on_mouse_exited():
	if $"../../Shared_Interface_Sounds/Hover".playing == true or $"../../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()
