extends Control

@onready var arrow = $Arrow
@onready var cross = $Cross

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	arrow.show()
	cross.hide()

func _process(_delta):
	$".".global_position = $".".get_global_mouse_position()

func _input(event):
	if event.is_action_pressed("Left_Click") or event.is_action_pressed("Right_Click"):
		toggle_cursors()

func toggle_cursors():
	if arrow.visible:
		arrow.hide()
		cross.show()
	else:
		arrow.show()
		cross.hide()
