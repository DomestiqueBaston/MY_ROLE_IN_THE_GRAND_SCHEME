extends Node2D

signal done

@onready var _option_button = $Chalkboard_Content/Chalk_Mask/Case/Case_Selector/Case_List
@onready var _id = $Chalkboard_Content/Chalk_Mask/Case_Report/Case/ID
@onready var _status = $Chalkboard_Content/Chalk_Mask/Case_Report/Case/Status
@onready var _deadline = $Chalkboard_Content/Chalk_Mask/Case_Report/Case/Delay
@onready var _info = $Chalkboard_Content/Chalk_Mask/Case_Report/VBoxContainer/Info_Container
@onready var _victims = $Chalkboard_Content/Chalk_Mask/Case_Report/VBoxContainer/Info_Container/Victim_Container
@onready var _witnesses = $Chalkboard_Content/Chalk_Mask/Case_Report/VBoxContainer/Info_Container/Witness_Container
@onready var _suspects = $Chalkboard_Content/Chalk_Mask/Case_Report/VBoxContainer/Info_Container/Suspect_Container
@onready var _crime_scene = $Chalkboard_Content/Chalk_Mask/Case_Report/VBoxContainer/Info_Container/Crime_Scene_Container
@onready var _ok_button = $Chalkboard_Content/Chalk_Mask/Ok
@onready var _cancel_button = $Chalkboard_Content/Chalk_Mask/Cancel

func _ready():
	_ok_button.mouse_entered.connect(_on_mouse_entered.bind(_ok_button))
	_ok_button.mouse_exited.connect(_on_mouse_exited.bind(_ok_button))
	_ok_button.pressed.connect(_on_ok_pressed)

	_cancel_button.mouse_entered.connect(_on_mouse_entered.bind(_cancel_button))
	_cancel_button.mouse_exited.connect(_on_mouse_exited.bind(_cancel_button))
	_cancel_button.pressed.connect(_on_cancel_pressed)

	_option_button.item_selected.connect(_on_item_selected)

func populate():
	_option_button.clear()
	for case: Case in GameState.cases:
		_option_button.add_item(case.get_random_name())
	_option_button.add_separator("Ready for a mess? Pick one and dive in...")
	_option_button.selected = _option_button.item_count - 1
	_ok_button.disabled = true
	_info.hide()

func _on_item_selected(index: int):
	var case: Case = GameState.cases[index]

	_id.text = case.get_case_id()

	match case.get_status():
		Case.Status.UNASSIGNED:
			_status.text = "Unassigned"
		Case.Status.ACTIVE:
			_status.text = "Active"
		Case.Status.PAUSED:
			_status.text = "Paused"
		Case.Status.DONE:
			_status.text = "Done"

	_deadline.text = "%d days" % case.get_duration()

	var victims = []
	var witnesses = []
	var suspects = []

	for npc in case.npcs:
		match npc.category:
			NpcCard.NpcCategory.VICTIM:
				victims.append(npc)
			NpcCard.NpcCategory.WITNESS:
				witnesses.append(npc)
			NpcCard.NpcCategory.SUSPECT:
				suspects.append(npc)

	_populate_npc_names(victims, _victims)
	_populate_npc_names(witnesses, _witnesses)
	_populate_npc_names(suspects, _suspects)

	if case.get_crime_location():
		var label = _crime_scene.get_node("Location1/Name")
		label.text = case.get_crime_location().get_display_name()
		_crime_scene.show()
	else:
		_crime_scene.hide()

	_info.show()
	_ok_button.disabled = false

func _populate_npc_names(npcs, node):
	var count = npcs.size()
	if count == 0:
		node.hide()
	else:
		node.get_node("NPC1").visible = true
		node.get_node("NPC2").visible = (count > 1)
		node.get_node("NPC3").visible = (count > 2)
		node.get_node("NPC1/Name").text = npcs[0].get_display_name()
		if count > 1:
			node.get_node("NPC2/Name").text = npcs[1].get_display_name()
		if count > 2:
			node.get_node("NPC3/Name").text = npcs[2].get_display_name()
		node.show()

func _on_mouse_entered(button: Button):
	if not button.disabled:
		if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
			Globals.hover_sound.play()

func _on_mouse_exited(button: Button):
	if not button.disabled:
		if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
			Globals.leave_sound.play()

func _on_cancel_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	if _option_button.selected < GameState.cases.size():
		GameState.set_current_case(_option_button.selected)
	done.emit()
