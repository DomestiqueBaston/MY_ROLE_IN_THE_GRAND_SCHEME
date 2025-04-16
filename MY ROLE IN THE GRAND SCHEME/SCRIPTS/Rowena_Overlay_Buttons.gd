extends Control


@onready var price_label = $Drug_Store/I_will_take/Price
@onready var stock_number_label = $Drug_Store/Stock/Stock_Number
@onready var purchase_label = $Drug_Store/I_will_take/Purchase

func _ready():
	stock_number_label.text = "5"
	purchase_label.text = "0"
	price_label.text = "0"

func _on_thanks_pressed():
	$"../Shared_Interface_Sounds/Valid".play()
	await $"../Shared_Interface_Sounds/Valid".finished
	$"../On_Off".play("Disappearance")
	await $"../On_Off".animation_finished

func _on_mouse_entered():
	if $"../Shared_Interface_Sounds/Leave".playing == true or $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Hover".play()

func _on_mouse_exited():
	if $"../Shared_Interface_Sounds/Leave".playing == true or $"../Shared_Interface_Sounds/Hover".playing == true:
		pass
	else:
		$"../Shared_Interface_Sounds/Leave".play()

func _on_nope_pressed():
	$"../Shared_Interface_Sounds/Cancel".play()
	await $"../Shared_Interface_Sounds/Cancel".finished
	$"../On_Off".play("Disappearance")
	await $"../On_Off".animation_finished

func _on_minus_pressed():
	$"../Shared_Interface_Sounds/Cancel".play()
	_update_price(-25)
	_update_stock_number(-1)

func _on_plus_pressed():
	$"../Shared_Interface_Sounds/Valid".play()
	_update_price(25)
	_update_stock_number(1)

# Fonction pour mettre à jour le label Price
func _update_price(amount: int):
	var current_price = int(price_label.text)
	current_price += amount
	if current_price < 0:
		current_price = 0
	elif current_price > 125:
		current_price = 125
	price_label.text = str(current_price)

# Fonction pour mettre à jour les labels Stock_Number et Purchase
func _update_stock_number(amount: int):
	var current_stock = int(stock_number_label.text)
	var current_purchase = int(purchase_label.text)

	if amount > 0 and current_stock > 0:
		current_stock -= 1
		current_purchase += 1
	elif amount < 0 and current_purchase > 0:
		current_stock += 1
		current_purchase -= 1

	stock_number_label.text = str(current_stock)
	purchase_label.text = str(current_purchase)
