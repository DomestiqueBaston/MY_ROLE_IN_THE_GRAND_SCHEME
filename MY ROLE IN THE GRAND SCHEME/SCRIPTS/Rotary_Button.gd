extends TextureButton

signal button_moved

var _button_position: int = 0
var _textures = [
	preload("res://GRAPHICS/INTERACTION/Rotary_Button_1.png"),
	preload("res://GRAPHICS/INTERACTION/Rotary_Button_2.png"),
	preload("res://GRAPHICS/INTERACTION/Rotary_Button_3.png"),
	preload("res://GRAPHICS/INTERACTION/Rotary_Button_4.png"),
	preload("res://GRAPHICS/INTERACTION/Rotary_Button_5.png"),
	preload("res://GRAPHICS/INTERACTION/Rotary_Button_6.png")
]

func _ready():
	_update_texture()

func _gui_input(event: InputEvent):
	var dir

	if event.is_action_pressed("Mouse_Wheel_Up"):
		dir = 1
	elif event.is_action_pressed("Mouse_Wheel_Down"):
		dir = -1
	else:
		return

	accept_event()
	_button_position = posmod(_button_position + dir, 6)
	_update_texture()
	button_moved.emit()

func get_button_position() -> int:
	return _button_position

func _update_texture():
	texture_normal = _textures[_button_position]
