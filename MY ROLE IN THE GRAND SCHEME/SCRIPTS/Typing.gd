extends RichTextLabel

var actual_value = 0.0
var pitch_values = [1.66, 0.66, 1.0]
var tutorial_text = ""
var json_files = [
	"res://JSON/TUTORIAL/tutorial_01.json",
	"res://JSON/TUTORIAL/tutorial_02.json",
	"res://JSON/TUTORIAL/tutorial_03.json",
	"res://JSON/TUTORIAL/tutorial_04.json"
]
var current_json_index = 0
var animation_player : AnimationPlayer
var click_delay = 1.0
var end_of_tuto = 0
var speed_factor = 1.0

func _ready():
	animation_player = get_node("../../../Typing_Animation")
	load_tutorial_text()

func load_tutorial_text():
	var file = FileAccess.open(json_files[current_json_index], FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()
	
	var json_parser = JSON.new()
	json_parser.parse(json_data)
	
	tutorial_text = json_parser.get_data().get("tutorial", "")
	actual_value = 0.0
	text = ""

func _process(_delta):
	if Input.is_action_pressed("Right_Click"):
		animation_player.speed_scale = 10.0 * speed_factor
	else:
		animation_player.speed_scale = 1.0 * speed_factor

	if tutorial_text != "":
		text = tutorial_text
	
	if $".".visible_ratio < 1.0:
		if not $"../../../Typing".is_playing():
			# There is an unwanted delay with the typing sound...
			if $".".visible_ratio > actual_value:
				var typing_sound = $"../../../Typing"
				typing_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]
				typing_sound.play()
				actual_value += .001
			else:
				actual_value = 0.

func _on_next_button_pressed():
	end_of_tuto += 1
	if end_of_tuto == 3:
		$"../Next_Button".text = "End of line!"
		$".".horizontal_alignment = 1
		$".".size.y = 170
		$".".position.y = 98
		speed_factor = 2.5
	if end_of_tuto == 4:
		get_tree().quit() #to change of course!
	current_json_index = (current_json_index + 1) % json_files.size()
	load_tutorial_text()
	animation_player.seek(0, true)
	animation_player.play("Display_Text")
