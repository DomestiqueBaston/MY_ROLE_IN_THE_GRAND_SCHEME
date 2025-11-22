extends Node2D

signal done

@onready var _total_price_label = $Drug_Store/I_will_take/Price
@onready var _price_label = $Drug_Store/Stock/HBoxContainer/Price
@onready var _stock_label = $Drug_Store/Stock/Stock_Number
@onready var _purchase_label = $Drug_Store/I_will_take/Purchase
@onready var _minus_button = $Drug_Store/I_will_take/Plus_Minus/Minus
@onready var _plus_button = $Drug_Store/I_will_take/Plus_Minus/Plus
@onready var _nope_button = $Thanks_Nope/HBoxContainer/Nope
@onready var _thanks_button = $Thanks_Nope/HBoxContainer/Thanks

var _doses_available: int = 5
var _doses_purchased: int = 0
var _funds: int = 0
var _price: int = 0

func reset(doses: int, funds: int, price: int):
	_doses_available = doses
	_doses_purchased = 0
	_funds = funds
	_price = price
	_update_ui()

func get_doses_purchased() -> int:
	return _doses_purchased

func _ready():
	_update_ui()

	_minus_button.pressed.connect(_on_minus_pressed)
	_minus_button.mouse_entered.connect(Globals.on_mouse_entered.bind(_minus_button))
	_minus_button.mouse_exited.connect(Globals.on_mouse_exited.bind(_minus_button))

	_plus_button.pressed.connect(_on_plus_pressed)
	_plus_button.mouse_entered.connect(Globals.on_mouse_entered.bind(_plus_button))
	_plus_button.mouse_exited.connect(Globals.on_mouse_exited.bind(_plus_button))

	_nope_button.pressed.connect(_on_nope_pressed)
	_nope_button.mouse_entered.connect(Globals.on_mouse_entered.bind(_nope_button))
	_nope_button.mouse_exited.connect(Globals.on_mouse_exited.bind(_nope_button))

	_thanks_button.pressed.connect(_on_thanks_pressed)
	_thanks_button.mouse_entered.connect(Globals.on_mouse_entered.bind(_thanks_button))
	_thanks_button.mouse_exited.connect(Globals.on_mouse_exited.bind(_thanks_button))

func _on_thanks_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()

func _on_nope_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	_doses_purchased = 0
	done.emit()

func _on_minus_pressed():
	if _doses_purchased > 0:
		Globals.cancel_sound.play()
		_doses_purchased -= 1
		_update_ui()

func _on_plus_pressed():
	if _doses_purchased < _doses_available:
		Globals.valid_sound.play()
		_doses_purchased += 1
		_update_ui()

func _update_ui():
	var total_price = _doses_purchased * _price
	_price_label.text = str(_price)
	_stock_label.text = str(_doses_available - _doses_purchased)
	_purchase_label.text = str(_doses_purchased)
	_total_price_label.text = str(total_price)
	_thanks_button.disabled = total_price == 0 or total_price > _funds
