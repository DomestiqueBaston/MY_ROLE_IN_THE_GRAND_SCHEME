extends Control

func _ready():
	$Ok.mouse_entered.connect(Globals.on_mouse_entered)
	$Ok.mouse_exited.connect(Globals.on_mouse_exited)
	$Ok.pressed.connect(_on_switch_pressed)

func _on_switch_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
