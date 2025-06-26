extends Node2D

var _is_macos = (OS.get_name() == "macOS")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
	# while the mouse is captured, we need to set the mouse position in
	# _input(), because the system mouse position is not updated
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return

	global_position = get_global_mouse_position().round()

	# on platforms other than macOS, the cursor is always made visible when it
	# leaves the window
	if _is_macos:
		if get_viewport_rect().has_point(global_position):
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent):
	# while the mouse is captured, we have to update its position using
	# InputEventMouseMouse.relative
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		global_position += event.relative

func grab_mouse():
	# stop updating the global mouse position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func release_mouse():
	# start updating the global mouse position again
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# put the mouse back where we want it
	Input.warp_mouse(get_viewport().get_screen_transform() * global_position)

func set_cursor(cursor: Globals.MouseCursor):
	$Arrow_Cursor.visible = (cursor == Globals.MouseCursor.ARROW)
	$Circle_Cursor.visible = (cursor == Globals.MouseCursor.CIRCLE)
	$Cross_Cursor.visible = (cursor == Globals.MouseCursor.CROSS)

func get_cursor() -> Globals.MouseCursor:
	if $Arrow_Cursor.visible:
		return Globals.MouseCursor.ARROW
	elif $Circle_Cursor.visible:
		return Globals.MouseCursor.CIRCLE
	else:
		return Globals.MouseCursor.CROSS
