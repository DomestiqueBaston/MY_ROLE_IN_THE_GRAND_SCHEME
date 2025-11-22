extends Node2D

func _ready():
	$Proposal_Content/Ok.mouse_entered.connect(Globals.on_mouse_entered)
	$Proposal_Content/Ok.mouse_exited.connect(Globals.on_mouse_exited)
	$Proposal_Content/Ok.pressed.connect(_on_ok_pressed)

	$Proposal_Content/Cancel.mouse_entered.connect(Globals.on_mouse_entered)
	$Proposal_Content/Cancel.mouse_exited.connect(Globals.on_mouse_exited)
	$Proposal_Content/Cancel.pressed.connect(_on_cancel_pressed)

func _on_cancel_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
