extends MenuButton


#The only way to have a transparent background!
#Source: https://forum.godotengine.org/t/optionbutton-theming-how-to-get-rid-of-the-popupmenu-grey-background/82655/2

func _ready():
	get_popup().transparent = true
