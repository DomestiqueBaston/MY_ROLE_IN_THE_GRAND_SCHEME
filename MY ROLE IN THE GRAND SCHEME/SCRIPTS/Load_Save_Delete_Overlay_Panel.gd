extends Control


func _on_load_pressed():
	$"../Shared_Interface_Sounds/Valid".play()
	await $"../Shared_Interface_Sounds/Valid".finished
	$"../On_Off".play("Disappearance")
	await $"../On_Off".animation_finished


func _on_save_pressed():
	$"../Shared_Interface_Sounds/Valid".play()
	await $"../Shared_Interface_Sounds/Valid".finished
	$"../On_Off".play("Disappearance")
	await $"../On_Off".animation_finished


func _on_delete_pressed():
	$"../Shared_Interface_Sounds/Cancel".play()
	await $"../Shared_Interface_Sounds/Cancel".finished
	$"../On_Off".play("Disappearance")
	await $"../On_Off".animation_finished


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

#Il y a un truc pas super chouette, il faudra revoir ça :
func _on_item_list_mouse_entered():
	$"../Shared_Interface_Sounds/Hover".play()

func _on_item_list_mouse_exited():
	$"../Shared_Interface_Sounds/Leave".play()

func _on_item_list_item_selected(_index: int):
	$"../Shared_Interface_Sounds/Valid".play()
	
