extends Control


func _on_any_button_mouse_entered():
	$"../../Hover".play()

func _on_cancel_pressed():
	$"../../Cancel".play()
	#await $"../../Cancel".finished

func _on_switch_pressed():
	$"../../Valid".play()

func _on_any_button_mouse_exited():
	$"../../Leave".play()
