extends OptionButton


func _on_button_down():
	Globals.hover_sound.play()

func _on_button_up():
	Globals.leave_sound.play()

func _on_item_selected(_index: int):
	Globals.valid_sound.play()
