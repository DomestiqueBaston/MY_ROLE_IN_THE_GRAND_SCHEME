extends RichTextLabel

var actual_value = 0.0
var pitch_values = [1.2, 0.8, 1.0]
var tutorial_text = ""
var json_files = [
	"res://JSON/TUTORIAL/tutorial_01.json",
	"res://JSON/TUTORIAL/tutorial_02.json",
	"res://JSON/TUTORIAL/tutorial_03.json"
]
var current_json_index = 0
var typing_complete = false
var animation_player : AnimationPlayer
var click_delay = 1.0
var time_since_last_click = 0.0

func _ready():
	animation_player = get_node("../../../AnimationPlayer")
	load_tutorial_text()

func load_tutorial_text():
	var file = FileAccess.open(json_files[current_json_index], FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()
	
	var json_parser = JSON.new()
	json_parser.parse(json_data)
	
	tutorial_text = json_parser.get_data().get("tutorial", "")
	typing_complete = false
	actual_value = 0.0
	text = ""

func _process(_delta):
	time_since_last_click += _delta
	
	if time_since_last_click >= click_delay:
		if Input.is_action_pressed("Left_Click"):
			current_json_index = (current_json_index + 1) % json_files.size()
			load_tutorial_text()
			animation_player.seek(0, true)
			animation_player.play("Display_Text")
			time_since_last_click = 0.0

	if Input.is_action_pressed("Right_Click"):
		animation_player.play("Display_Text", -1, 2.0)
	else:
		animation_player.play("Display_Text", -1, 1.0)

	if tutorial_text != "":
		text = tutorial_text
	
	if $".".visible_ratio < 1.0:
		if not $"../../../Typing".is_playing():
			if $".".visible_ratio > actual_value:
				var typing_sound = $"../../../Typing"
				typing_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]
				typing_sound.play()
				actual_value += .001
			else:
				actual_value = 0.
