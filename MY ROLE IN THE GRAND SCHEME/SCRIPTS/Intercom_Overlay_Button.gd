extends TextureButton


func _on_pressed():
	$"../../../Shared_Interface_Sounds/Valid".play()
	await $"../../../Shared_Interface_Sounds/Valid".finished
	$"../../../Intercom".stop()
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished

func _on_mouse_entered():
	if $"../../../Shared_Interface_Sounds/Leave".playing == true or $"../../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../../../Shared_Interface_Sounds/Hover".playing == true or $"../../../Shared_Interface_Sounds/Leave".playing == true:
		pass
	else:
		$"../../../Shared_Interface_Sounds/Leave".play()


func _on_on_off_animation_finished(_anim_name: StringName) -> void:
	await get_tree().create_timer(0.4).timeout
	$"../Screens".show()
