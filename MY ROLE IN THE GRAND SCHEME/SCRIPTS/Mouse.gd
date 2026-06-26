extends Node2D

var _is_macos = (OS.get_name() == "macOS")

var _arrow1: Texture2D = preload("res://GRAPHICS/UI/Mouse_Arrow_1.png")
var _arrow2: Texture2D = preload("res://GRAPHICS/UI/Mouse_Arrow_2.png")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _notification(what: int):
	# on macOS only, the cursor remains invisible when the mouse leaves the
	# window
	if _is_macos:
		match what:
			NOTIFICATION_WM_MOUSE_ENTER:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			NOTIFICATION_WM_MOUSE_EXIT:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta):
	# while the mouse is captured, we need to set the mouse position in
	# _input(), because the system mouse position is not updated
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		global_position = get_global_mouse_position().round()

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

func set_alternate_style(alternate: bool):
	$Arrow_Cursor.texture = _arrow2 if alternate else _arrow1

func is_alternate_style() -> bool:
	return $Arrow_Cursor.texture == _arrow2
