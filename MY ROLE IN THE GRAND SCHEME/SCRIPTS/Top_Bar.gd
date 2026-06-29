extends Control

## If true, all menus except Whatever are disabled.
@export var limited_menus: bool = false

## If false, don't listen for changes to player attributes, time, etc.
@export var listen_for_changes: bool = true

## Signal emitted when the player selects Deadlines from the case menu.
signal show_deadlines

## Signal emitted when the player selects Validate Case from the menu.
signal validate_case

## Signal emitted when the player selects Give Up Case from the menu.
signal abandon_case

## Signal emitted when the player selects Case Management from the menu.
signal manage_cases

## Signal emitted when the player selects Card Management from the menu.
signal manage_cards

## Signal emitted when the player selects Settings from the menu.
signal settings

## Signal emitted when the player selects Quit from the menu.
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
	var alert_timer: Timer

	@warning_ignore("shadowed_global_identifier")
	func _init(
		name: String, label: Label, min: int = 0, max: int = 0,
		alert: AnimationPlayer = null, timer: Timer = null):
		attr_name = name
		ui_label = label
		min_value = min
		max_value = max
		alert_player = alert
		alert_timer = timer

@onready var _attrs: Array[PlayerAttr] = [
	PlayerAttr.new("physical", $Character_Stats/PHY, 1, 1000, $PHY_Alert, $PHY_Alert_Timer),
	PlayerAttr.new("mental", $Character_Stats/MEN, 1, 1000, $MEN_Alert, $MEN_Alert_Timer),
	PlayerAttr.new("health", $Character_Stats/HEA, 1, 1000, $HEA_Alert, $HEA_Alert_Timer),
	PlayerAttr.new("emotion", $Character_Stats/Emo, -4, 4, $Emo_Alert),
	PlayerAttr.new("addiction", $Character_Stats/Add, -4, 4, $Add_Alert),
	PlayerAttr.new("wanted", $Character_Stats/Wan, -1000, 4, $Wan_Alert),
	PlayerAttr.new("money", $Character_Stats/Dough),
	PlayerAttr.new("drugs", $Character_Stats/Drug)
]

@onready var _dailies_button: MenuButton = $Menus/Dailies

enum DailiesMenuItem {
	WARRANT = 1000,
	DOCTOR,
	DEALER,
	INVESTIGATION_CENTER,
	OFFICE,
	PASS_TIME,
	SLEEP,
	DEBT_SUBMENU,
	DRUG_SUBMENU
}

enum CasesMenuItem {
	MANAGE,
	VALIDATE,
	GIVE_UP,
	DEADLINES
}

enum WhateverMenuItem {
	SETTINGS,
	QUIT
}

var _day_names = [
	"Mon.",
	"Tue.",
	"Wed.",
	"Thu.",
	"Fri.",
	"Sat.",
	"Sun."
]

var _debt_popup: PopupMenu
var _drug_popup: PopupMenu

func _update_controls():
	var player = GameState.player
	$Character_Stats/Player_Name.text = player.player_name
	for attr in _attrs:
		_on_attr_changed(attr, false)
	_on_debts_changed()
	_on_time_changed()

func _enter_tree():
	if is_node_ready():
		_update_controls()

func _ready():
	_update_controls()

	if listen_for_changes:
		for attr in _attrs:
			GameState.connect(
				attr.attr_name + "_changed", _on_attr_changed.bind(attr, true))
			if attr.alert_timer:
				attr.alert_timer.timeout.connect(_on_attr_alert_timeout.bind(attr))
		GameState.debts_changed.connect(_on_debts_changed)
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
			button.mouse_entered.connect(Globals.on_mouse_entered)
			button.mouse_exited.connect(Globals.on_mouse_exited)
			button.pressed.connect(_on_button_pressed)

	$Menus/Cases.get_popup().id_pressed.connect(_on_cases_press)
	$Menus/Cases.get_popup().about_to_popup.connect(_on_cases_popup)
	$Menus/Cards.get_popup().id_pressed.connect(func(_id): manage_cards.emit())
	$Menus/Whatever.get_popup().id_pressed.connect(_on_whatever_press)

	if _dailies_button.disabled:
		return

	_debt_popup = PopupMenu.new()
	_debt_popup.index_pressed.connect(_on_debt_menu_pressed)

	_drug_popup = PopupMenu.new()
	_drug_popup.add_item("Use 1 dose")
	_drug_popup.add_item("Use 2 doses")
	_drug_popup.index_pressed.connect(_on_drug_menu_pressed)

	var popup: PopupMenu = _dailies_button.get_popup()
	popup.about_to_popup.connect(_on_dailies_menu_popup)
	popup.add_item("Buy a search warrant...", DailiesMenuItem.WARRANT)
	popup.add_item("Visit Doctor F...", DailiesMenuItem.DOCTOR)
	popup.add_item("Visit Rowena the dealer...", DailiesMenuItem.DEALER)
	popup.add_item(
		"Go to the Investig. Center...", DailiesMenuItem.INVESTIGATION_CENTER)
	popup.add_item("Back to the office!", DailiesMenuItem.OFFICE)
	popup.add_separator(" - - - - - - - - - - - - - ")
	popup.add_submenu_node_item(
		"Pay the bill", _debt_popup, DailiesMenuItem.DEBT_SUBMENU)
	popup.add_submenu_node_item(
		"Get your fix", _drug_popup, DailiesMenuItem.DRUG_SUBMENU)
	popup.add_separator(" - - - - - - - - - - - - - ")
	popup.add_item("Go to sleep...", DailiesMenuItem.SLEEP)
	popup.add_item("Pass time!", DailiesMenuItem.PASS_TIME)
	popup.id_pressed.connect(_on_dailies_press)

func _on_dailies_press(id: int):
	match id:
		DailiesMenuItem.WARRANT:
			GameState.buy_search_warrant()
		DailiesMenuItem.DOCTOR:
			GameState.visit_doctor()
		DailiesMenuItem.DEALER:
			GameState.visit_dealer()
		DailiesMenuItem.INVESTIGATION_CENTER:
			GameState.visit_investigation_center()
		DailiesMenuItem.OFFICE:
			GameState.visit_office()
		DailiesMenuItem.PASS_TIME:
			GameState.pass_time()
			$Menu_Bip.play()
		DailiesMenuItem.SLEEP:
			var hours = await Globals.dialog_overlay.choose_sleep_time()
			if hours > 0:
				GameState.sleep(hours)

func _on_cases_popup():
	var case: Case = GameState.get_current_case()
	var popup: PopupMenu = $Menus/Cases.get_popup()
	var index = popup.get_item_index(CasesMenuItem.MANAGE)
	popup.set_item_disabled(
		index, GameState.get_open_cases().size() < 2 or GameState.is_final_case())
	index = popup.get_item_index(CasesMenuItem.VALIDATE)
	popup.set_item_disabled(index, case == null or case.selected_motive.is_empty())
	index = popup.get_item_index(CasesMenuItem.GIVE_UP)
	popup.set_item_disabled(
		index,
		not (case and case.can_be_abandoned()
			 and GameState.can_visit_investigation_center())
		or GameState.is_final_case())
	index = popup.get_item_index(CasesMenuItem.DEADLINES)
	popup.set_item_disabled(index, GameState.get_open_cases().is_empty())

func _on_cases_press(id: int):
	match id:
		CasesMenuItem.MANAGE:
			manage_cases.emit()
		CasesMenuItem.VALIDATE:
			validate_case.emit()
		CasesMenuItem.GIVE_UP:
			abandon_case.emit()
		CasesMenuItem.DEADLINES:
			show_deadlines.emit()

func _on_whatever_press(id: int):
	match id:
		WhateverMenuItem.SETTINGS:
			settings.emit()
		WhateverMenuItem.QUIT:
			quit.emit()

func _on_button_pressed():
	Globals.valid_sound.play()

func _on_attr_changed(attr: PlayerAttr, alert_to_all_changes: bool = true):
	var value = GameState.player[attr.attr_name]
	attr.ui_label.text = str(value)
	if attr.alert_player:
		if value <= attr.min_value or value >= attr.max_value:
			if attr.alert_timer:
				attr.alert_timer.stop()
			if attr.alert_player.current_animation != "Alert":
				attr.alert_player.play("Alert")
		elif alert_to_all_changes:
			if attr.alert_timer:
				attr.alert_timer.start()
				attr.alert_player.play("Alert")
			else:
				if attr.alert_player.current_animation == "Alert":
					attr.alert_player.play("RESET")

func _on_attr_alert_timeout(attr: PlayerAttr):
	attr.alert_player.play("RESET")

func _on_debts_changed():
	if GameState.player.get_debt_count() >= 4:
		$Date_Time/Day.tooltip_text = "You need to pay your bills!"
		if $Bill_Alert.current_animation != "Alert":
			$Bill_Alert.play("Alert")
	else:
		$Date_Time/Day.tooltip_text = ""
		if $Bill_Alert.current_animation == "Alert":
			$Bill_Alert.play("RESET")

func _on_time_changed():
	$Date_Time/Day.text = _day_names[GameState.get_day() % 7]

	var hour = GameState.get_hour()
	if hour < 12:
		$Date_Time/Time.text = "%dam" % (12 if hour == 0 else hour)
	else:
		$Date_Time/Time.text = "%dpm" % (12 if hour == 12 else hour - 12)

	var player = GameState.player
	if player.get_hours_awake() < 16 or player.is_paranoid():
		$Date_Time/Time.tooltip_text = ""
		$Sleep_Alert.play("RESET")
	else:
		$Date_Time/Time.tooltip_text = "You need to sleep!"
		$Sleep_Alert.play("Alert")

func _on_dailies_menu_popup():
	var player: Player = GameState.player
	var popup: PopupMenu = _dailies_button.get_popup()
	var item_index

	# can the player buy a search warrant?

	item_index = popup.get_item_index(DailiesMenuItem.WARRANT)
	if player.has_search_warrant:
		popup.set_item_text(item_index, "Search warrant secured")
		popup.set_item_disabled(item_index, true)
	else:
		popup.set_item_text(item_index, "Buy a search warrant...")
		popup.set_item_disabled(
			item_index,
			player.money < GameState.get_warrant_price() \
			or player.get_debt_count() > 0 \
			or not GameState.can_visit_warrant_desk() \
			or player.is_paranoid())

	# can the player go to the doctor?

	item_index = popup.get_item_index(DailiesMenuItem.DOCTOR)
	popup.set_item_disabled(
		item_index,
		not GameState.can_visit_doctor() or player.is_paranoid())

	# can the player go see his dealer?

	item_index = popup.get_item_index(DailiesMenuItem.DEALER)
	popup.set_item_disabled(
		item_index,
		not GameState.can_visit_dealer() or player.is_paranoid())

	# can the player visit the investigation center?

	item_index = popup.get_item_index(DailiesMenuItem.INVESTIGATION_CENTER)
	popup.set_item_disabled(
		item_index,
		not GameState.can_visit_investigation_center() or player.is_paranoid())

	# can the player go to the office?

	item_index = popup.get_item_index(DailiesMenuItem.OFFICE)
	popup.set_item_disabled(
		item_index,
		GameState.get_player_location() == GameState.PlayerLocation.OFFICE)

	# can the player sleep?

	item_index = popup.get_item_index(DailiesMenuItem.SLEEP)
	popup.set_item_disabled(
		item_index, not player.can_sleep() or player.is_paranoid())

	# populate the debts submenu with an item for each debt

	_debt_popup.clear()

	for i in player.get_debt_count():
		var debt = player.get_debt(i)
		var label
		if i == 0:
			label = "This week (%d Dø)" % debt
		else:
			label = "%d weeks ago (%d Dø)" % [i+1, debt]
		_debt_popup.add_item(label)
		_debt_popup.set_item_disabled(i, player.money < debt)

	# if the player has no debts or is paranoid, disable the submenu

	var dailies: PopupMenu = _dailies_button.get_popup()
	var index = dailies.get_item_index(DailiesMenuItem.DEBT_SUBMENU)
	if player.get_debt_count() == 0 or player.is_paranoid():
		dailies.set_item_disabled(index, true)
	else:
		dailies.set_item_disabled(index, false)

	# enable/disable drug submenu and items as appropriate

	index = dailies.get_item_index(DailiesMenuItem.DRUG_SUBMENU)
	if player.drugs < 1 or player.drugs_taken_today >= 2 or player.is_paranoid():
		dailies.set_item_disabled(index, true)
	else:
		dailies.set_item_disabled(index, false)
		_drug_popup.set_item_disabled(1, player.drugs < 2 or player.drugs_taken_today > 0)

func _on_debt_menu_pressed(index: int):
	$Menu_Bip.play()
	await GameState.pay_debt(index)

func _on_drug_menu_pressed(index: int):
	$Menu_Bip.play()
	await GameState.use_drugs(1 + index)
