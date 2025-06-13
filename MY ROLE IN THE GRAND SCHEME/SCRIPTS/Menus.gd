extends Control

func _ready():
	var submenu1: PopupMenu = PopupMenu.new()
	submenu1.add_item("This week (XXXDø)")
	submenu1.add_item("2 weeks ago (XXXDø)")
	submenu1.add_item("3 weeks ago (XXXDø)")
	submenu1.add_item("4 weeks ago (XXXDø)")

	var submenu2: PopupMenu = PopupMenu.new()
	submenu2.add_item("Use 1 dose")
	submenu2.add_item("Use 2 doses")

	var popup: PopupMenu = $Dailies.get_popup()
	popup.add_item("Buy a search warrant...")
	popup.add_item("Visit Doctor F...")
	popup.add_item("Visit Rowena the dealer...")
	popup.add_item("Go to the Investig. Center...")
	popup.add_item("Back to the office!")
	popup.add_separator(" - - - - - - - - - - - - - ")
	popup.add_submenu_node_item("Pay the bill", submenu1)
	popup.add_submenu_node_item("Get your fix", submenu2)
	popup.add_separator(" - - - - - - - - - - - - - ")
	popup.add_item("Go to sleep...")
	popup.add_item("Pass time")

	for button: MenuButton in [$Dailies, $Cases, $Cards, $Whatever]:
		button.mouse_entered.connect(_on_mouse_entered)
		button.mouse_exited.connect(_on_mouse_exited)
		button.pressed.connect(_on_pressed)

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.leave_sound.play()

func _on_pressed():
	Globals.valid_sound.play()
