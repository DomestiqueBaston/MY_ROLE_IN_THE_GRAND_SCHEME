extends Sprite2D

var _is_macos = (OS.get_name() == "macOS")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
	global_position = get_global_mouse_position().round()
	
	# on platforms other than macOS, the cursor is always made visible when it
	# leaves the window
	if _is_macos:
		if get_viewport_rect().has_point(global_position):
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
