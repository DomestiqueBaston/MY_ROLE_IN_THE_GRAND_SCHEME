extends Node2D

var _is_macos = (OS.get_name() == "macOS")

func _ready():
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		set_process(false)

func _notification(what: int):

	# on macOS only, in MOUSE_MODE_HIDDEN mode, the system cursor remains
	# invisible when the mouse leaves the window, so we explicitly show it
	# until it reenters the window

	if _is_macos and visible:
		match what:
			NOTIFICATION_WM_MOUSE_ENTER:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			NOTIFICATION_WM_MOUSE_EXIT:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta):
	global_position = get_global_mouse_position().round()

func set_enabled(enabled: bool):
	visible = enabled
	set_process(enabled)
	Input.set_mouse_mode(
		Input.MOUSE_MODE_HIDDEN if enabled else Input.MOUSE_MODE_VISIBLE)

func is_enabled() -> bool:
	return visible

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
