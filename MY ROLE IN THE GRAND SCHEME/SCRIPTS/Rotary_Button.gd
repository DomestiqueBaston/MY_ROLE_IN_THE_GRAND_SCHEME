extends TextureButton

var button_position : int = 1
var textures : Array = [
	"res://GRAPHICS/INTERACTION/Rotary_Button_1.png",
	"res://GRAPHICS/INTERACTION/Rotary_Button_2.png",
	"res://GRAPHICS/INTERACTION/Rotary_Button_3.png",
	"res://GRAPHICS/INTERACTION/Rotary_Button_4.png",
	"res://GRAPHICS/INTERACTION/Rotary_Button_5.png",
	"res://GRAPHICS/INTERACTION/Rotary_Button_6.png"
]

var time_elapsed : float = 0.0
var is_condition_met : bool = false
var last_top_button_position : int = -1
var last_bottom_button_position : int = -1

@onready var top_button = get_node("/root/Interaction/Top_Left_Screen/Rotary_Buttons/Top_Rotary_Button")
@onready var bottom_button = get_node("/root/Interaction/Top_Left_Screen/Rotary_Buttons/Bottom_Rotary_Button")

func _ready():
	update_texture()

func _process(_delta):
	if top_button.button_position != last_top_button_position or bottom_button.button_position != last_bottom_button_position:
		if not $"../../Movies/MFSC".paused:
			stop_movie_MFSC()
		elif not $"../../Movies/DB".paused:
			stop_movie_DB()
		elif not $"../../Movies/KM".paused:
			stop_movie_KM()
		elif not $"../../Movies/JJ".paused:
			stop_movie_JJ()

		last_top_button_position = top_button.button_position
		last_bottom_button_position = bottom_button.button_position

	if is_mouse_over_button():
		if Input.is_action_just_pressed("Mouse_Wheel_Up"):
			button_position += 1
			if button_position > 6:
				button_position = 1
			$"../../Turn_Button".play()
			update_texture()

		elif Input.is_action_just_pressed("Mouse_Wheel_Down"):
			button_position -= 1
			if button_position < 1:
				button_position = 6
			$"../../Turn_Button".play()
			update_texture()

	if top_button.button_position == 2 and bottom_button.button_position == 5:
		if is_condition_met:
			time_elapsed += _delta
			if time_elapsed >= 0.666:
				go_movie_MFSC()
		else:
			is_condition_met = true
			time_elapsed = 0.0
	elif top_button.button_position == 3 and bottom_button.button_position == 6:
		if is_condition_met:
			time_elapsed += _delta
			if time_elapsed >= 0.666:
				go_movie_DB()
		else:
			is_condition_met = true
			time_elapsed = 0.0
	elif top_button.button_position == 3 and bottom_button.button_position == 2:
		if is_condition_met:
			time_elapsed += _delta
			if time_elapsed >= 0.666:
				go_movie_KM()
		else:
			is_condition_met = true
			time_elapsed = 0.0
	elif top_button.button_position == 6 and bottom_button.button_position == 5:
		if is_condition_met:
			time_elapsed += _delta
			if time_elapsed >= 0.666:
				go_movie_JJ()
		else:
			is_condition_met = true
			time_elapsed = 0.0
	else:
		is_condition_met = false
		time_elapsed = 0.0

func is_mouse_over_button() -> bool:
	var mouse_pos = get_local_mouse_position()
	var button_rect = get_rect()
	if mouse_pos.x >= 0 and mouse_pos.x <= button_rect.size.x and mouse_pos.y >= 0 and mouse_pos.y <= button_rect.size.y:
		return true
	return false

func update_texture():
	if button_position >= 1 and button_position <= 6:
		texture_normal = load(textures[button_position - 1])

func go_movie_MFSC():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Movies/MFSC".visible = true
		$"../../Movies/MFSC".paused = false
	else:
		stop_movie_MFSC()

func stop_movie_MFSC():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Movies/MFSC".paused = true
		$"../../Movies/MFSC".visible = false
		$"../../Line_Animation".visible = not $"../../Line_Animation".visible
		$"../../Interaction".visible = not $"../../Interaction".visible
		$"../../Screen".visible = true
	else:
		$"../../Movies/MFSC".paused = true
		$"../../Movies/MFSC".visible = false
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Screen".visible = false

func go_movie_DB():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Movies/DB".visible = true
		$"../../Movies/DB".paused = false
	else:
		stop_movie_DB()
		
func stop_movie_DB():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Movies/DB".paused = true
		$"../../Movies/DB".visible = false
		$"../../Line_Animation".visible = not $"../../Line_Animation".visible
		$"../../Interaction".visible = not $"../../Interaction".visible
		$"../../Screen".visible = true
	else:
		$"../../Movies/DB".paused = true
		$"../../Movies/DB".visible = false
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Screen".visible = false
		
func go_movie_KM():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Movies/KM".visible = true
		$"../../Movies/KM".paused = false
	else:
		stop_movie_KM()
		
func stop_movie_KM():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Movies/KM".paused = true
		$"../../Movies/KM".visible = false
		$"../../Line_Animation".visible = not $"../../Line_Animation".visible
		$"../../Interaction".visible = not $"../../Interaction".visible
		$"../../Screen".visible = true
	else:
		$"../../Movies/KM".paused = true
		$"../../Movies/KM".visible = false
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Screen".visible = false
		
func go_movie_JJ():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Movies/JJ".visible = true
		$"../../Movies/JJ".paused = false
	else:
		stop_movie_JJ()
		
func stop_movie_JJ():
	if $"../../Tv_On_Off".button_pressed == false:
		$"../../Movies/JJ".paused = true
		$"../../Movies/JJ".visible = false
		$"../../Line_Animation".visible = not $"../../Line_Animation".visible
		$"../../Interaction".visible = not $"../../Interaction".visible
		$"../../Screen".visible = true
	else:
		$"../../Movies/JJ".paused = true
		$"../../Movies/JJ".visible = false
		$"../../Line_Animation".visible = false
		$"../../Interaction".visible = false
		$"../../Screen".visible = false
