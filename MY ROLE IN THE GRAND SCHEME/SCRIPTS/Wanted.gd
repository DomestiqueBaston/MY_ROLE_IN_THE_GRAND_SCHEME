extends Node2D

signal done

var _pay_clicked: bool

func _ready():
	for button in [$Info/Player/Surrender, $Info/Player/Pay, $Info/NPC/Ok]:
		button.mouse_entered.connect(Globals.on_mouse_entered)
		button.mouse_exited.connect(Globals.on_mouse_exited)

	$Info/Player/Surrender.pressed.connect(_on_surrender_pressed)
	$Info/Player/Pay.pressed.connect(_on_pay_pressed)
	$Info/NPC/Ok.pressed.connect(_on_pay_pressed)

func start(can_pay: bool):
	$Police.play()
	$Info/Player/Pay.disabled = not can_pay

func is_pay_clicked() -> bool:
	return _pay_clicked

func _on_surrender_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	$Police.stop()
	_pay_clicked = false
	done.emit()

func _on_pay_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$Police.stop()
	_pay_clicked = true
	done.emit()
