extends OptionButton


func _on_button_down():
	$"../../../../../Shared_Interface_Sounds/Hover".play()

func _on_button_up():
	$"../../../../../Shared_Interface_Sounds/Leave".play()

func _on_item_selected(_index: int):
	$"../../../../../Shared_Interface_Sounds/Valid".play()
