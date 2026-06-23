extends Node2D

signal done

@onready var victim_name: RichTextLabel = \
	$Proposal_Content/Case_Report/VBoxContainer/Info_Container/Victim_Container/Link_01/NPC_01
@onready var witness_name: RichTextLabel = \
	$Proposal_Content/Case_Report/VBoxContainer/Info_Container/Witness_Container/Link_01/NPC_01
@onready var suspect_name: RichTextLabel = \
	$Proposal_Content/Case_Report/VBoxContainer/Info_Container/Suspect_Container/Link_01/NPC_01
@onready var crime_scene: RichTextLabel = \
	$Proposal_Content/Case_Report/VBoxContainer/Info_Container/Crime_Scene_Container/Link_02/Location_01

var _accepted: bool

func _ready():
	$Proposal_Content/Ok.mouse_entered.connect(Globals.on_mouse_entered)
	$Proposal_Content/Ok.mouse_exited.connect(Globals.on_mouse_exited)
	$Proposal_Content/Ok.pressed.connect(_on_ok_pressed)

	$Proposal_Content/Cancel.mouse_entered.connect(Globals.on_mouse_entered)
	$Proposal_Content/Cancel.mouse_exited.connect(Globals.on_mouse_exited)
	$Proposal_Content/Cancel.pressed.connect(_on_cancel_pressed)

func start(case: Case):
	$Proposal_Content/Case_Report/Case_Delivery/Delay.text = \
		"%d days" % case.get_duration()
	$Proposal_Content/Case_Report/Case_Name/Name.text = case.get_case_name()
	$Proposal_Content/Case_Report/Description.text = \
		case.get_motive_dictionary().get("more_explicit_name_2", "")

	victim_name.text = ""
	witness_name.text = ""
	suspect_name.text = ""

	for npc in case.npcs:
		match npc.actual_role:
			NpcCard.NpcRole.VICTIM:
				victim_name.text = npc.get_display_name()
			NpcCard.NpcRole.WITNESS:
				witness_name.text = npc.get_display_name()
			NpcCard.NpcRole.SUSPECT:
				suspect_name.text = npc.get_display_name()

	var location: LocationCard = case.get_crime_location()
	crime_scene.text = location.get_display_name() if location else ""

	_accepted = false

func get_accepted() -> bool:
	return _accepted

func _on_cancel_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	done.emit()

func _on_ok_pressed():
	_accepted = true
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
