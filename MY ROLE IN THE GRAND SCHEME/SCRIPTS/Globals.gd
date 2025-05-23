extends Node

@onready var valid_sound: AudioStreamPlayer = $UI_Sounds/Valid
@onready var cancel_sound: AudioStreamPlayer = $UI_Sounds/Cancel
@onready var leave_sound: AudioStreamPlayer = $UI_Sounds/Leave
@onready var hover_sound: AudioStreamPlayer = $UI_Sounds/Hover
@onready var card_entered_sound: AudioStreamPlayer = $UI_Sounds/Card_Entered
@onready var card_exited_sound: AudioStreamPlayer = $UI_Sounds/Card_Exited

## Indicates whether or not the user is in the middle of a drag & drop.
var dragging = false

@warning_ignore("unused_signal")
signal card_left_click(pos: Vector2, card: Card)

@warning_ignore("unused_signal")
signal card_right_click(pos: Vector2, card: Card)

@warning_ignore("unused_signal")
signal mouse_entered_card(card: Card)

@warning_ignore("unused_signal")
signal mouse_exited_card(card: Card)

@warning_ignore("unused_signal")
signal link_right_click(pos: Vector2, link: Link)

func _ready():
	# the mouse is drawn on top of menus
	$MouseLayer.set_layer(1025)
	# the shaders are drawn on top of the mouse
	$ShaderOverlayLayer.set_layer(1026)
	# and the shaders are visible even if they are turned off in the editor
	$ShaderOverlayLayer.visible = true
	
	# only topmost cards and links receive input events
	var viewport = get_viewport()
	viewport.physics_object_picking = true
	viewport.physics_object_picking_sort = true
	viewport.physics_object_picking_first_only = true

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("Full_Screen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Escape"):
		get_tree().quit()
		get_viewport().set_input_as_handled()

##
## As long as the mouse is "grabbed", mouse motion events will report no
## movement, meaning that nodes' _input() methods will not detect any movement.
## The user, however, will not see the difference: see the Mouse_Cursor node.
## Be sure to call release_mouse() when done.
##
func grab_mouse():
	$MouseLayer/Mouse_Cursor.grab_mouse()

##
## "Ungrabs" the mouse after a call to grab_mouse().
##
func release_mouse():
	$MouseLayer/Mouse_Cursor.release_mouse()
