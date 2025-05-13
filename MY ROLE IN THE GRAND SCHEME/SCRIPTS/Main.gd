extends Node2D

@onready var popup: PopupMenu = $Popup/Main_Menu

func _ready():
	popup.add_item("Dialogue")
	popup.add_item("Investigation")
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_submenu_node_item("Create conf. link", $Popup/Main_Menu/Sub_Menu)
	popup.add_submenu_node_item("Create prob. link", $Popup/Main_Menu/Sub_Menu)
	popup.add_submenu_node_item("Change link color", $Popup/Main_Menu/Sub_Menu)
	popup.add_item("Switch conf./prob.")
	popup.add_item("Delete link")
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_item("Throw card away")
	
	Globals.popup_card_menu.connect(_popup_menu)
	Globals.popup_link_menu.connect(_popup_menu)

func _popup_menu(pos: Vector2, node: Node2D):
	if node is Card:
		if node.find_parent("TMP_2"):
			return
		print("popup menu for card ", node.get_card_name())
	elif node is Link:
		print("popup menu for link ", node.get_name())
	else:
		print("popup menu for node ", node.get_name())
	popup.popup(Rect2i(pos, Vector2i()))
