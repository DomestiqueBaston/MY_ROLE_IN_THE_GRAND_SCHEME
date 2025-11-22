extends Node2D

signal done

var _confirmed: bool

func _ready():
	$Note/Yes.pressed.connect(_on_yes_pressed)
	$Note/Yes.mouse_entered.connect(Globals.on_mouse_entered)
	$Note/Yes.mouse_exited.connect(Globals.on_mouse_exited)

	$Note/No.pressed.connect(_on_no_pressed)
	$Note/No.mouse_entered.connect(Globals.on_mouse_entered)
	$Note/No.mouse_exited.connect(Globals.on_mouse_exited)

func set_price(price: int):
	$Note/Price.text = str(price)

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
