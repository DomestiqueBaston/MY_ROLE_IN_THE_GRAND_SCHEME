extends OptionButton


#The only way to have a transparent background!
#Source: https://forum.godotengine.org/t/optionbutton-theming-how-to-get-rid-of-the-popupmenu-grey-background/82655/2

func _ready():
	get_popup().transparent = true
	get_popup().max_size = Vector2(162, 101)

func _on_item_selected(_index: int): #le "_" de _index temporairement pouréviter l'erreur...
	$"../../Valid".play()

func _on_button_down():
	$"../../Hover".play()

func _on_button_up():
	$"../../Leave".play()
