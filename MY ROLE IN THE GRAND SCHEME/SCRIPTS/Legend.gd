extends Control

@onready var _color_buttons = {
	$Hideout_White:				Link.Type.HIDEOUT,
	$Debt_Influence_Gray:		Link.Type.DEBT,
	$Culp_Acco_Evid_Black:		Link.Type.GUILT,
	$Intimacy_Pink:				Link.Type.INTIMACY,
	$Friend_Dark_Green:			Link.Type.FRIEND,
	$Enemy_Orange:				Link.Type.ENEMY,
	$Acquaintance_Light_Blue:	Link.Type.ACQUAINTANCE,
	$Ideology_Dark_Blue:		Link.Type.IDEOLOGY,
	$Contradiction_Red:			Link.Type.CONTRADICTION,
	$Validation_Yellow:			Link.Type.CONFIRMATION,
	$Property_Light_Green:		Link.Type.PROPERTY,
	$Home_Brown:				Link.Type.HOME,
	$Work_Turquoise:			Link.Type.WORK,
	$Hangout_Darkest_Blue:		Link.Type.HANGOUT,
	$Found_Light_Purple:		Link.Type.FOUND,
	$New_Dark_Purple:			-1
}

func _ready():
	$Reset.mouse_entered.connect(_on_mouse_enter)
	$Reset.mouse_exited.connect(_on_mouse_exit)
	$Reset.pressed.connect(_reset)

	for button in _color_buttons:
		button.mouse_entered.connect(_on_mouse_enter)
		button.mouse_exited.connect(_on_mouse_exit)
		button.toggled.connect(_on_toggle.bind(_color_buttons[button]))

func _on_mouse_enter():
	if not Globals.hover_sound.playing and not Globals.leave_sound.playing:
		Globals.hover_sound.play()

func _on_mouse_exit():
	if not Globals.hover_sound.playing and not Globals.leave_sound.playing:
		Globals.leave_sound.play()

func _reset():
	Globals.cancel_sound.play()
	for button in _color_buttons:
		button.button_pressed = false
	Globals.reset_link_mask()

func _on_toggle(toggled_on: bool, link_type: int):
	if toggled_on:
		Globals.valid_sound.play()
	else:
		Globals.cancel_sound.play()
	if link_type < 0:
		Globals.set_dotted_links_visible(not toggled_on)
	else:
		Globals.set_link_mask(link_type as Link.Type, not toggled_on)
