extends Node2D

@export var popup_menu: PopupMenu


func _input(_event):
	if Input.is_action_pressed("Right_Click"):
		var position_globale = get_global_mouse_position()
		var rect = Rect2i(position_globale, popup_menu.size)
		$Shared_Interface_Sounds/Cancel.play()
		popup_menu.popup(rect)

	if Input.is_action_pressed("Left_Click"):
		$Shared_Interface_Sounds/Valid.play()
		popup_menu.hide()

# Il manque le code pour les sons de navigation dans le menu...
