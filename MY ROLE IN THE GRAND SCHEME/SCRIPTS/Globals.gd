extends Node2D

@onready var valid_sound: AudioStreamPlayer = $UI_Sounds/Valid
@onready var cancel_sound: AudioStreamPlayer = $UI_Sounds/Cancel
@onready var leave_sound: AudioStreamPlayer = $UI_Sounds/Leave
@onready var hover_sound: AudioStreamPlayer = $UI_Sounds/Hover
@onready var card_entered_sound: AudioStreamPlayer = $UI_Sounds/Card_Entered
@onready var card_exited_sound: AudioStreamPlayer = $UI_Sounds/Card_Exited

## Overlay used to block the UI while asking the player a question.
@onready var dialog_overlay: Node2D = $DialogLayer/Short_Event_Overlay

## Indicates whether or not the user is in the middle of a drag & drop.
var dragging: bool = false

## Available mouse cursor types.
enum MouseCursor {
	ARROW,
	CIRCLE,
	CROSS
}

@warning_ignore("unused_signal")
signal card_left_click(pos: Vector2, card: Card)

@warning_ignore("unused_signal")
signal card_right_click(pos: Vector2, card: Card)

@warning_ignore("unused_signal")
signal card_double_click(card: Card)

@warning_ignore("unused_signal")
signal mouse_entered_card(card: Card)

@warning_ignore("unused_signal")
signal mouse_exited_card(card: Card)

@warning_ignore("unused_signal")
signal pin_left_click(pos: Vector2, pin: Pin)

@warning_ignore("unused_signal")
signal link_right_click(pos: Vector2, link: Link)

@warning_ignore("unused_signal")
signal mouse_entered_link(link: Link)

@warning_ignore("unused_signal")
signal mouse_exited_link(link: Link)

@warning_ignore("unused_signal")
signal link_visibility_changed

@onready var _mouse: Node2D = $MouseLayer/Mouse

var _link_mask: int = -1
var _show_dotted_links: bool = true
var _mouse_cursor_stack: Array[MouseCursor]

const _settings_path = "user://settings.cfg"
var _volume: Array[float]

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
	
	for bus in AudioServer.bus_count:
		_volume.append(AudioServer.get_bus_volume_linear(bus))
	
	load_settings()

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
## Hides the mouse cursor (temporarily).
##
func hide_ui_layers():
	$MouseLayer.hide()
	#$ShaderOverlayLayer.hide()

##
## Makes the mouse cursor visible after a call to hide_ui_layers().
##
func show_ui_layers():
	$MouseLayer.show()
	#$ShaderOverlayLayer.show()

##
## As long as the mouse is "grabbed", mouse motion events will report no
## movement, meaning that nodes' _input() methods will not detect any movement.
## The user, however, will not see the difference: see the Mouse node. Be sure
## to call release_mouse() when done.
##
func grab_mouse():
	_mouse.grab_mouse()

##
## "Ungrabs" the mouse after a call to grab_mouse().
##
func release_mouse():
	_mouse.release_mouse()

##
## Returns the mouse cursor currently displayed.
##
func get_mouse_cursor() -> MouseCursor:
	return _mouse.get_cursor()

##
## Specifies the mouse cursor to display.
##
func set_mouse_cursor(cursor: MouseCursor):
	_mouse.set_cursor(cursor)

##
## Saves the mouse cursor currently displayed and activates the given cursor
## instead.
##
func push_mouse_cursor(cursor: MouseCursor):
	_mouse_cursor_stack.push_back(_mouse.get_cursor())
	_mouse.set_cursor(cursor)

##
## Restores the mouse cursor that was displayed before the previous call to
## push_mouse_cursor().
##
func pop_mouse_cursor():
	_mouse.set_cursor(_mouse_cursor_stack.pop_back())

##
## Specifies whether links of the given type are visible or not. By default,
## all link types are visible.
##
func set_link_mask(link_type: Link.Type, vis: bool):
	if vis:
		_link_mask |= 1 << link_type
	else:
		_link_mask &= ~(1 << link_type)
	link_visibility_changed.emit()

##
## Specifies whether unconfirmed/probable links are visible or not. By default,
## they are.
##
func set_dotted_links_visible(vis: bool):
	_show_dotted_links = vis
	link_visibility_changed.emit()

##
## Returns true if the given link should be visible, given the current state of
## the link mask and dotted link flag.
##
func is_link_visible(link: Link) -> bool:
	if not _show_dotted_links and link.status != Link.Status.CONFIRMED:
		return false
	return _link_mask & (1 << link.type) != 0

##
## Resets the link mask and dotted link flag so that all links are visible.
##
func show_all_links():
	_link_mask = -1
	_show_dotted_links = true
	link_visibility_changed.emit()

##
## Sets the link mask and dotted link flag so that all links are hidden.
##
func hide_all_links():
	_link_mask = 0
	_show_dotted_links = false
	link_visibility_changed.emit()

##
## (Re)loads previously saved settings (e.g. sound levels). This is done
## automatically at startup.
##
func load_settings():
	var config = ConfigFile.new()
	if config.load(_settings_path) == OK:
		for bus in AudioServer.bus_count:
			var bus_name = AudioServer.get_bus_name(bus)
			var volume = config.get_value("volume", bus_name, -1)
			if volume >= 0:
				AudioServer.set_bus_volume_linear(bus, volume)

##
## Saves current settings (e.g. sound levels) to disk.
##
func save_settings():
	var config = ConfigFile.new()
	for bus in AudioServer.bus_count:
		var bus_name = AudioServer.get_bus_name(bus)
		var volume = AudioServer.get_bus_volume_linear(bus)
		config.set_value("volume", bus_name, volume)
	config.save(_settings_path)

func get_volume(bus_name: StringName) -> float:
	var bus = AudioServer.get_bus_index(bus_name)
	var volume = AudioServer.get_bus_volume_linear(bus)
	return volume

func set_volume(bus_name: StringName, volume: float):
	var bus = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_linear(bus, volume)
