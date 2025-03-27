extends Control


func _on_ok_pressed():
	$"../Valid".play()

func _on_ok_mouse_entered():
	$"../Hover".play()

func _on_ok_mouse_exited():
	$"../Leave".play()
