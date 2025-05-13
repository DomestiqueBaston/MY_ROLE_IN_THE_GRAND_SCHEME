class_name Card extends Node2D

func get_card_name():
	return $Card_Mask/Card_BG/Card_Text/Card_Name.text

func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.popup_card_menu.emit(event.global_position, self)
