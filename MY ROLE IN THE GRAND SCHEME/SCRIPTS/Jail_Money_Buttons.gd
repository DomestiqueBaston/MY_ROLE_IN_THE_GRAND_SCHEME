extends Control

func _ready():
	for button in [$Player/Surrender, $Player/Pay, $NPC/Ok]:
		button.mouse_entered.connect(Globals.on_mouse_entered)
		button.mouse_exited.connect(Globals.on_mouse_exited)
	$Player/Surrender.pressed.connect(_on_surrender_pressed)
	$Player/Pay.pressed.connect(_on_pay_pressed)
	$NPC/Ok.pressed.connect(_on_pay_pressed)

	if $"..".visible:
		$"../Police".play()

func _on_surrender_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	$"../Police".stop()
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished

func _on_pay_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$"../Police".stop()
	$"../../../On_Off".play("Disappearance")
	await $"../../../On_Off".animation_finished
