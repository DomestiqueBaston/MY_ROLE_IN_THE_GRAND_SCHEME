extends Control

@onready var arrow = $Arrow
@onready var cross = $Cross
@onready var arrow_1 = $Arrow/Arrow_1
@onready var arrow_2 = $Arrow/Arrow_2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
	global_position = get_global_mouse_position()

func toggle_cursors():
	arrow.visible = !arrow.visible
	cross.visible = !cross.visible

func toggle_arrows():
	arrow_1.visible = !arrow_1.visible
	arrow_2.visible = !arrow_2.visible
