extends Node2D

@export var sound_fade_time: float = 0.2333

@onready var valid_sound: AudioStreamPlayer = $UI_Sounds/Valid
@onready var cancel_sound: AudioStreamPlayer = $UI_Sounds/Cancel
@onready var leave_sound: AudioStreamPlayer = $UI_Sounds/Leave
@onready var hover_sound: AudioStreamPlayer = $UI_Sounds/Hover
@onready var card_entered_sound: AudioStreamPlayer = $UI_Sounds/Card_Entered
@onready var card_exited_sound: AudioStreamPlayer = $UI_Sounds/Card_Exited
@onready var lock_sound: AudioStreamPlayer = $UI_Sounds/Lock_Card
@onready var unlock_sound: AudioStreamPlayer = $UI_Sounds/Unlock_Card
@onready var paranoia_voices: AudioStreamPlayer = $Ambiance_Sound/Paranoia_Voices

## Overlay used to block the UI while asking the player a question.
@onready var dialog_overlay: Node2D = $DialogLayer/Short_Event_Overlay

## Indicates whether or not the user is in the middle of a drag & drop.
var dragging: bool = false

## The default game difficulty level (see game_difficulty).
const default_game_difficulty: int = 2

## Game difficulty levels are in the range [0 4].
var game_difficulty: int = default_game_difficulty

## Drug quality flag: when set, drug prices are higher.
var drug_quality_flag: bool = false

## Plot depth flag: when set, player has less time to solve cases.
var plot_depth_flag: bool = false

## Corruption flag: when set, search warrant prices are higher.
var corruption_flag: bool = false

## Inflation flag: when set, bills are more expensive.
var inflation_flag: bool = false

## Vice flag: when set, prices to avoid prison or abandon a case are higher.
var vice_flag: bool = false

## Liars flag: when set, it is more likely that NPCs will lie.
var liars_flag: bool = false

## Hardboiled minions flag: when set, minions have greater HEA.
var hardboiled_minions_flag: bool = false

## No public medicine flag: when set, visits to the doctor are more expensive.
var no_public_medicine_flag: bool = false

## Hectic city flag: when set, there are more useless NPCs in each case.
var hectic_city_flag: bool = false

## They are watching flag: when set, player receives more anonymous messages.
var they_are_watching_flag: bool = false

## Cat's eye flag: when set, player receives a malus for daytime interactions
## rather than nighttime interactions.
var cats_eye_flag: bool = false

## I am one of them flag: when set, the player is never sent to prison.
var i_am_one_of_them_flag: bool = false

## Available mouse cursor types.
enum MouseCursor {
	ARROW,
	CIRCLE,
	CROSS
}

## Available background music.
enum Music {
	MAIN,
	INVESTIGATION,
	DIALOGUE,
	COMBAT,
	REQUIEM
}

# AudioStreamPlayer for each music stream.
@onready var _music_players: Array[AudioStreamPlayer] = [
	$Music/Music_Main,
	$Music/Music_Investigation,
	$Music/Music_Dialogue,
	$Music/Music_Combat,
	$Music/Music_Requiem
]

# Current playback position for each music stream.
var _music_pos = [
	0.0,
	0.0,
	0.0,
	0.0,
	0.0
]

var _paranoia_voice_current_level: float = 0.0

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
var _current_music: int = -1

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
## Enables or disables display of the shader overlay (video effects that make
## everything harder to read). By default, display is enabled.
##
func set_shader_overlay_enabled(enabled: bool):
	$ShaderOverlayLayer.visible = enabled

##
## Returns true if display of the shader overlay is enabled.
##
func is_shader_overlay_enabled() -> bool:
	return $ShaderOverlayLayer.visible

##
## Hides the mouse cursor (temporarily).
##
func hide_mouse():
	$MouseLayer.hide()

##
## Makes the mouse cursor visible after a call to hide_mouse().
##
func show_mouse():
	$MouseLayer.show()

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
	if _mouse_cursor_stack.is_empty():
		push_error("pop_mouse_cursor: stack is empty!")
	else:
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
		game_difficulty = \
			config.get_value("settings", "difficulty", default_game_difficulty)
		drug_quality_flag = config.get_value("settings", "drug_quality", false)
		plot_depth_flag = config.get_value("settings", "plot_depth", false)
		corruption_flag = config.get_value("settings", "corruption", false)
		inflation_flag = config.get_value("settings", "inflation", false)
		vice_flag = config.get_value("settings", "vice", false)
		liars_flag = config.get_value("settings", "liars", false)
		hardboiled_minions_flag = \
			config.get_value("settings", "hardboiled_minions", false)
		no_public_medicine_flag = \
			config.get_value("settings", "no_public_medicine", false)
		hectic_city_flag = config.get_value("settings", "hectic_city", false)
		they_are_watching_flag = \
			config.get_value("settings", "they_are_watching", false)
		cats_eye_flag = config.get_value("settings", "cats_eye_flag", false)
		i_am_one_of_them_flag = \
			config.get_value("settings", "i_am_one_of_them", false)
		$ShaderOverlayLayer.visible = \
			config.get_value("settings", "video_shader", true)

##
## Saves current settings (e.g. sound levels) to disk.
##
func save_settings():
	var config = ConfigFile.new()
	for bus in AudioServer.bus_count:
		var bus_name = AudioServer.get_bus_name(bus)
		var volume = AudioServer.get_bus_volume_linear(bus)
		config.set_value("volume", bus_name, volume)
	config.set_value("settings", "difficulty", game_difficulty)
	config.set_value("settings", "drug_quality", drug_quality_flag)
	config.set_value("settings", "plot_depth", plot_depth_flag)
	config.set_value("settings", "corruption", corruption_flag)
	config.set_value("settings", "inflation", inflation_flag)
	config.set_value("settings", "vice", vice_flag)
	config.set_value("settings", "liars", liars_flag)
	config.set_value("settings", "hardboiled_minions", hardboiled_minions_flag)
	config.set_value("settings", "no_public_medicine", no_public_medicine_flag)
	config.set_value("settings", "hectic_city", hectic_city_flag)
	config.set_value("settings", "they_are_watching", they_are_watching_flag)
	config.set_value("settings", "cats_eye", cats_eye_flag)
	config.set_value("settings", "i_am_one_of_them", i_am_one_of_them_flag)
	config.set_value("settings", "video_shader", $ShaderOverlayLayer.visible)
	config.save(_settings_path)

func get_volume(bus_name: StringName) -> float:
	var bus = AudioServer.get_bus_index(bus_name)
	var volume = AudioServer.get_bus_volume_linear(bus)
	return volume

func set_volume(bus_name: StringName, volume: float):
	var bus = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_linear(bus, volume)

func on_mouse_entered(button: BaseButton = null):
	if button and button.disabled:
		return
	if not (leave_sound.playing or hover_sound.playing):
		hover_sound.play()

func on_mouse_exited(button: BaseButton = null):
	if button and button.disabled:
		return
	if not (hover_sound.playing or leave_sound.playing):
		leave_sound.play()

func init_city_sounds():
	$Ambiance_Sound/City_Sound.play("Starter")

func start_city_sounds():
	if not $Ambiance_Sound/City_Noise.playing:
		$Ambiance_Sound/City_Sound.play("Fade_In")

func stop_city_sounds():
	if $Ambiance_Sound/City_Noise.playing:
		$Ambiance_Sound/City_Sound.play("Fade_Out")

##
## Sets the volume level of the paranoia voices heard by the player (between 0
## and 1). The voices are heard in the same conditions as the music, so they are
## faded in and out by start_music() and stop_music().
##
func set_paranoia_voice_level(level: float):
	if _paranoia_voice_current_level == level:
		return
	_paranoia_voice_current_level = level
	if _current_music < 0:
		return
	var tween = get_tree().create_tween()
	if level > 0.0:
		if not paranoia_voices.playing:
			paranoia_voices.volume_linear = 0.0
			paranoia_voices.play()
		tween.tween_property(paranoia_voices, "volume_linear", level, sound_fade_time)
	else:
		tween.tween_property(paranoia_voices, "volume_linear", 0.0, sound_fade_time)
		tween.tween_callback(paranoia_voices.stop)

##
## Fades out the current music, if any, and fades in the given music. Also fades
## in the paranoia voices, depending on the player's paranoia level. Does
## nothing if the given music is already playing.
##
func start_music(music: Music):
	if _current_music != music:
		_stop_music_only()
		var player: AudioStreamPlayer = _music_players[music]
		var tween = get_tree().create_tween()
		player.volume_db = -80.0
		player.play(_music_pos[music])
		tween.tween_property(player, "volume_db", 0.0, sound_fade_time)
		if not paranoia_voices.playing and _paranoia_voice_current_level > 0.0:
			paranoia_voices.volume_linear = 0.0
			paranoia_voices.play()
			tween.parallel().tween_property(
				paranoia_voices, "volume_linear", _paranoia_voice_current_level, sound_fade_time)
		_current_music = music

##
## Fades out the music that is currently playing, if any, and the paranoia
## voices, depending on the player's paranoia level.
##
func stop_music():
	_stop_music_only()
	if paranoia_voices.playing:
		var tween = get_tree().create_tween()
		tween.tween_property(paranoia_voices, "volume_linear", 0.0, sound_fade_time)
		tween.tween_callback(paranoia_voices.stop)

#
# Stops the music, but leaves the paranoia voices playing, if they are playing.
#
func _stop_music_only():
	if _current_music >= 0:
		var player: AudioStreamPlayer = _music_players[_current_music]
		var tween = get_tree().create_tween()
		_music_pos[_current_music] = player.get_playback_position()
		tween.tween_property(player, "volume_db", -80.0, sound_fade_time)
		tween.tween_callback(player.stop)
		_current_music = -1
