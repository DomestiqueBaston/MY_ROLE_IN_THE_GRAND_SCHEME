extends AnimationPlayer


func _on_animation_finished(anim_name: String):
	if anim_name == "Alert_Sound":
		play("Alert_No_Sound")
