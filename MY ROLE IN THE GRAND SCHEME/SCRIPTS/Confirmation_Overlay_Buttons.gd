extends Control


func _on_yes_pressed():
	$"../../Valid".play()

func _on_no_pressed():
	$"../../Cancel".play()

func _on_any_button_entered():
	$"../../Hover".play()

func _on_any_button_exited():
	$"../../Leave".play()
