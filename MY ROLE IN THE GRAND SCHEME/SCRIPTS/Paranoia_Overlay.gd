extends Node2D


var next = 0

func _ready():
	$On_Off.animation_finished.connect(_on_animation_finished)

func _process(_delta):
	if Input.is_action_just_pressed("Left_Click"):
		next += 1
		if next == 1:
			$On_Off.play("Disappearance")
		if next == 2:
			$On_Off.play("Final_Disappearance")
			
			
func _on_animation_finished(anim_name: String):
	if anim_name == "Final_Disappearance":
		get_tree().quit()
