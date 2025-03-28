extends MenuButton


#The only way to have a transparent background!
#Source: https://forum.godotengine.org/t/optionbutton-theming-how-to-get-rid-of-the-popupmenu-grey-background/82655/2

func _ready():
	get_popup().transparent = true


func _on_mouse_entered():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../../Shared_Interface_Sounds/Leave".playing == true or $"../../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../../Shared_Interface_Sounds/Leave".play()

func _on_pressed():
	$"../../Shared_Interface_Sounds/Valid".play()
