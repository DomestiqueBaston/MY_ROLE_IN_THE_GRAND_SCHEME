extends Control

signal done

var _confirmed: bool

func _ready():
	for button in [$Run_Away/Yes, $Run_Away/No, $Break_In/Yes, $Break_In/No]:
		button.mouse_entered.connect(Globals.on_mouse_entered)
		button.mouse_exited.connect(Globals.on_mouse_exited)

	$Run_Away/Yes.pressed.connect(_on_yes_pressed)
	$Run_Away/No.pressed.connect(_on_no_pressed)
	$Break_In/Yes.pressed.connect(_on_yes_pressed)
	$Break_In/No.pressed.connect(_on_no_pressed)

func get_confirmed() -> bool:
	return _confirmed

func _on_yes_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	_confirmed = true
	done.emit()

func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	_confirmed = false
	done.emit()
