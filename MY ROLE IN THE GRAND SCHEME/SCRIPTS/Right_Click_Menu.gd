extends Node2D

@export var popup_menu: PopupMenu


func _input(_event):
	if Input.is_action_pressed("Right_Click"):
		var position_toto = get_global_mouse_position()
		var rect = Rect2i(position_toto, popup_menu.size) 
		popup_menu.popup(rect)

	if Input.is_action_pressed("Left_Click"):
		popup_menu.hide()
