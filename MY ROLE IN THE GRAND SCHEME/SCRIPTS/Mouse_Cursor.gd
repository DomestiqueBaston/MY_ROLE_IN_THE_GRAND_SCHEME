extends Control

@onready var arrow = $Arrow
@onready var cross = $Cross
@onready var arrow_1 = $Arrow/Arrow_1
@onready var arrow_2 = $Arrow/Arrow_2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	arrow.show()
	cross.hide()

func _process(_delta):
	$".".global_position = $".".get_global_mouse_position()

func _input(event):
	if event.is_action_pressed("Left_Click"):
		toggle_cursors()
	if event.is_action_pressed("Right_Click"):
		toggle_arrows()

func toggle_cursors():
	if arrow.visible:
		arrow.hide()
		cross.show()
	else:
		arrow.show()
		cross.hide()

func toggle_arrows():
	if arrow_1.visible:
		arrow_1.hide()
		arrow_2.show()
	else:
		arrow_1.show()
		arrow_2.hide()
