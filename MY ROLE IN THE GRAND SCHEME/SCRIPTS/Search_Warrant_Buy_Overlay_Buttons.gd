extends Control


func _on_yes_pressed():
	$"../../Shared_Interface_Sounds/Valid".play()
	await $"../../Shared_Interface_Sounds/Valid".finished
	$"../../On_Off".play("Disappearance")
	await $"../../On_Off".animation_finished

func _on_no_pressed():
	$"../../Shared_Interface_Sounds/Cancel".play()
	await $"../../Shared_Interface_Sounds/Cancel".finished
	$"../../On_Off".play("Disappearance")
	await $"../../On_Off".animation_finished

func _on_mouse_entered():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()
