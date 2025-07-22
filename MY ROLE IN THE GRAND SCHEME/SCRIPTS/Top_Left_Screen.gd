extends Node2D

@onready var _top_button = $Rotary_Buttons/Top_Rotary_Button
@onready var _bottom_button = $Rotary_Buttons/Bottom_Rotary_Button
@onready var _on_off_button = $Tv_On_Off

var _current_movie: VideoStreamPlayer

func _ready():
	var roll = randi() % 3
	$Line_Animation/Dialogue.visible = (roll == 0)
	$Interaction/Dialogue.visible = (roll == 0)
	$Line_Animation/Combat.visible = (roll == 1)
	$Interaction/Combat.visible = (roll == 1)
	$Line_Animation/Investigation.visible = (roll == 2)
	$Interaction/Investigation.visible = (roll == 2)

	_on_off_button.pressed.connect(_on_on_off_pressed)
	_top_button.button_moved.connect(_on_dial_moved)
	_bottom_button.button_moved.connect(_on_dial_moved)

	$Timer.timeout.connect(_on_timeout)

func _on_on_off_pressed():
	$Tv_Switch.play()
	_update_tv()

func _on_dial_moved():
	$Turn_Button.play()
	if _current_movie:
		_current_movie.paused = true
		_current_movie.hide()
	$Timer.start(0)

func _on_timeout():
	var top = _top_button.get_button_position()
	var bottom = _bottom_button.get_button_position()
	#print("%d %d" % [top, bottom])

	if top == 2 and bottom == 5:
		_current_movie = $Movies/DB
	elif top == 2 and bottom == 1:
		_current_movie = $Movies/KM
	elif top == 5 and bottom == 4:
		_current_movie = $Movies/JJ
	else:
		_current_movie = null

	_update_tv()

func _update_tv():
	var on = _on_off_button.button_pressed
	$White_Noise.playing = on
	$Screen.visible = on
	$Line_Animation.visible = (on and not _current_movie)
	$Interaction.visible = (on and not _current_movie)
	if _current_movie:
		_current_movie.visible = on
		_current_movie.paused = not on
