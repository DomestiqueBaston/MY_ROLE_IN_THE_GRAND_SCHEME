extends Node2D

signal done

var _sms_data = preload("res://JSON/NARRATION/SMS.json").data
var _signatures = ["Anonymous", "Le corbeau", "D.B."]

func _ready():
	$Buttons/Ok.connect("mouse_entered", Globals.on_mouse_entered)
	$Buttons/Ok.connect("mouse_exited", Globals.on_mouse_exited)
	$Buttons/Ok.connect("pressed", _on_ok_pressed)

func _on_ok_pressed():
	$Blinking_Button.play("RESET")
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()

func send_random_message():
	var category = _sms_data.keys().pick_random()
	var text = _sms_data[category].pick_random()
	var signature = _signatures.pick_random()
	$Message_Window/Message.text = text + "\n\n" + signature
	$Blinking_Button.play("Blinking")
