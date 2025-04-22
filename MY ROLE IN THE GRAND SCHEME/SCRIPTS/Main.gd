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

func _unhandled_input(event: InputEvent):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		popup.popup(Rect2i(event.global_position, Vector2i()))
		get_viewport().set_input_as_handled()
