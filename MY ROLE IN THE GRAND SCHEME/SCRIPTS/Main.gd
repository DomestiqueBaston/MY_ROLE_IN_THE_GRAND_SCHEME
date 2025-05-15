extends Node2D

@onready var popup: PopupMenu = $Mask_Card_Playground/Popup/Main_Menu

var _current_card: Card

func _ready():
	popup.add_item("Dialogue")
	popup.add_item("Investigation")
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_submenu_node_item("Create conf. link", $Mask_Card_Playground/Popup/Main_Menu/Sub_Menu)
	popup.add_submenu_node_item("Create prob. link", $Mask_Card_Playground/Popup/Main_Menu/Sub_Menu)
	popup.add_submenu_node_item("Change link color", $Mask_Card_Playground/Popup/Main_Menu/Sub_Menu)
	popup.add_item("Switch conf./prob.")
	popup.add_item("Delete link")
	popup.add_separator("  - - - - - - - - - -  ")
	popup.add_item("Throw card away")
	
	Globals.card_right_click.connect(_popup_menu)
	Globals.card_double_click.connect(_expand_or_reduce_card)
	Globals.set_current_card.connect(_show_card_info)
	Globals.link_right_click.connect(_popup_menu)

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

func _expand_or_reduce_card(_pos: Vector2, card: Card):
	card.expand_or_reduce()

func _show_card_info(card: Card):
	if card != _current_card:
		print("show info about card ", card.get_card_name())
		_current_card = card
