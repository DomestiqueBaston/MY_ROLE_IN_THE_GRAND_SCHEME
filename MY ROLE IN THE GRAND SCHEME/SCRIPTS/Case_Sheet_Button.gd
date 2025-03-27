extends Control


func _on_quit_pressed():
	$"../Valid".play()

func _on_quit_mouse_entered():
	$"../Hover".play()

func _on_quit_mouse_exited():
	$"../Leave".play()
