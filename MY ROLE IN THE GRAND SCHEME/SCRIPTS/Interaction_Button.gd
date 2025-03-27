extends Control



func _on_bring_it_on_pressed():
	$Valid.play()

func _on_bring_it_on_mouse_entered():
	$"../Hover".play()

func _on_bring_it_on_mouse_exited():
	$"../Leave".play()
