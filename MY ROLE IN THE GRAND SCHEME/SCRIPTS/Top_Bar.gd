extends Control

## If true, all menus except Whatever are disabled.
@export var limited_menus: bool = false

## Signal emitted when the player selects Sleep from the menu.
signal sleep

## Signal emitted when the player selects Pass Time from the menu.
signal pass_time

## Signal emitted when the player select Quit from the menu.
signal quit

# Define player attributes, where they are displayed, their acceptable ranges,
# and the animations that show alerts when the attributes go outside their
# ranges.

class PlayerAttr:
	var attr_name: String
	var ui_label: Label
	var min_value: int
	var max_value: int
	var alert_player: AnimationPlayer

	@warning_ignore("shadowed_global_identifier")
	func _init(
		name: String, label: Label, min: int = 0, max: int = 0,
		alert: AnimationPlayer = null):
		attr_name = name
		ui_label = label
		min_value = min
		max_value = max
		alert_player = alert

@onready var _attrs: Array[PlayerAttr] = [
	PlayerAttr.new("physical", $Character_Stats/PHY, 1, 1000, $PHY_Alert),
	PlayerAttr.new("mental", $Character_Stats/MEN, 1, 1000, $MEN_Alert),
	PlayerAttr.new("health", $Character_Stats/HEA, 1, 1000, $HEA_Alert),
	PlayerAttr.new("emotion", $Character_Stats/Emo, -2, 2, $Emo_Alert),
	PlayerAttr.new("addiction", $Character_Stats/Add, -2, 2, $Add_Alert),
	PlayerAttr.new("wanted", $Character_Stats/Wan, 0, 3, $Wan_Alert),
	PlayerAttr.new("money", $Character_Stats/Dough),
	PlayerAttr.new("drugs", $Character_Stats/Drug)
]

enum DailiesMenuItem {
	PASS_TIME = 1000,
	SLEEP
}

enum WhateverMenuItem {
	LSD,
	OPTIONS,
	QUIT
}

func _update_controls():
	var player = GameState.player
	$Character_Stats/Player_Name.text = player.player_name
	for attr in _attrs:
		attr.ui_label.text = str(player[attr.attr_name])
	_on_time_changed()

func _enter_tree():
	if is_node_ready():
		_update_controls()

func _ready():
	_update_controls()

	var player = GameState.player
	for attr in _attrs:
		player.connect(attr.attr_name + "_changed", _on_attr_changed.bind(attr))
	player.debts_changed.connect(_on_debts_changed)
	GameState.time_changed.connect(_on_time_changed)

	# menu buttons and whether or not they are always enabled
	var buttons = {
		$Menus/Dailies:		false,
		$Menus/Cases:		false,
		$Menus/Cards:		false,
		$Menus/Whatever:	true
	}

	for button: MenuButton in buttons:
		var enabled = not limited_menus or buttons[button]
		button.disabled = not enabled
		if enabled:
			button.mouse_entered.connect(_on_mouse_entered)
			button.mouse_exited.connect(_on_mouse_exited)
			button.pressed.connect(_on_button_pressed)

	$Menus/Whatever.get_popup().id_pressed.connect(_on_whatever_press)

	if $Menus/Dailies.disabled:
		return

	var submenu1: PopupMenu = PopupMenu.new()
	submenu1.add_item("This week (XXXDø)")
	submenu1.add_item("2 weeks ago (XXXDø)")
	submenu1.add_item("3 weeks ago (XXXDø)")
	submenu1.add_item("4 weeks ago (XXXDø)")

	var submenu2: PopupMenu = PopupMenu.new()
	submenu2.add_item("Use 1 dose")
	submenu2.add_item("Use 2 doses")

	var popup: PopupMenu = $Menus/Dailies.get_popup()
	popup.add_item("Buy a search warrant...")
	popup.add_item("Visit Doctor F...")
	popup.add_item("Visit Rowena the dealer...")
	popup.add_item("Go to the Investig. Center...")
	popup.add_item("Back to the office!")
	popup.add_separator(" - - - - - - - - - - - - - ")
	popup.add_submenu_node_item("Pay the bill", submenu1)
	popup.add_submenu_node_item("Get your fix", submenu2)
	popup.add_separator(" - - - - - - - - - - - - - ")
	popup.add_item("Go to sleep...", DailiesMenuItem.SLEEP)
	popup.add_item("Pass time!", DailiesMenuItem.PASS_TIME)
	popup.id_pressed.connect(_on_dailies_press)

func _on_dailies_press(id: int):
	match id:
		DailiesMenuItem.PASS_TIME:
			pass_time.emit()
		DailiesMenuItem.SLEEP:
			sleep.emit()

func _on_whatever_press(id: int):
	match id:
		WhateverMenuItem.QUIT:
			quit.emit()

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.leave_sound.play()

func _on_button_pressed():
	Globals.valid_sound.play()

func _on_attr_changed(attr: PlayerAttr):
	var value = GameState.player[attr.attr_name]
	attr.ui_label.text = str(value)
	if attr.alert_player:
		if value < attr.min_value or value < attr.max_value:
			if attr.alert_player.current_animation != "Alert":
				attr.alert_player.play("Alert")
		else:
			if attr.alert_player.current_animation == "Alert":
				attr.alert_player.play("Reset")

func _on_debts_changed():
	if GameState.player.get_debt_count() >= 4:
		$Date_Time/Day.tooltip_text = "You need to pay your bills!"
		if $Bill_Alert.current_animation != "Alert":
			$Bill_Alert.play("Alert")
	else:
		$Date_Time/Day.tooltip_text = ""
		if $Bill_Alert.current_animation == "Alert":
			$Bill_Alert.play("RESET")

var _day_names = [
	"Mon.",
	"Tue.",
	"Wed.",
	"Thu.",
	"Fri.",
	"Sat.",
	"Sun."
]

func _on_time_changed():
	$Date_Time/Day.text = _day_names[GameState.get_day() % 7]
	var hour = GameState.get_hour()
	if hour < 12:
		$Date_Time/Time.text = "%dam" % (12 if hour == 0 else hour)
	else:
		$Date_Time/Time.text = "%dpm" % (12 if hour == 12 else hour - 12)
