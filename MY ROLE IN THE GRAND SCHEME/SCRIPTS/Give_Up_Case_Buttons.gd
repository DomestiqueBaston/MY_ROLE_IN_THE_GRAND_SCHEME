extends Node2D

signal done

var _answer: bool

func _ready():
	$Yes_No/Yes.pressed.connect(_on_yes_pressed)
	$Yes_No/Yes.mouse_entered.connect(Globals.on_mouse_entered)
	$Yes_No/Yes.mouse_exited.connect(Globals.on_mouse_exited)

	$Yes_No/No.pressed.connect(_on_no_pressed)
	$Yes_No/No.mouse_entered.connect(Globals.on_mouse_entered)
	$Yes_No/No.mouse_exited.connect(Globals.on_mouse_exited)

func set_fee(fee: int):
	$Fee.text = str(fee)
	$Yes_No/Yes.disabled = GameState.player.money < fee

func get_answer() -> bool:
	return _answer

func _on_yes_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	_answer = true
	done.emit()

func _on_no_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	_answer = false
	done.emit()
