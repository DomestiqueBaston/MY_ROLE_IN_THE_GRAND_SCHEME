extends Control


func _on_any_button_plus_pressed():
	$Valid.play()

func _on_any_button_moins_pressed():
	$Cancel.play()

func _on_any_button_pressed():
	$Valid.play()

func _on_cancel_pressed():
	$Cancel.play()

func _on_any_button_mouse_entered():
	$Hover.play()
	
func _on_any_button_mouse_exited():
	$Leave.play()

func _on_h_slider_value_changed(value: float): #le "_" de _index temporairement pouréviter l'erreur...
	var pitch = lerp(0.5, 0.51, value)
	$Sex_Choice.pitch_scale = pitch
	if not $Sex_Choice.playing:
		$Sex_Choice.play()

func _process(delta):
	if Input.is_action_just_released("Left_Click"):  # Si l'action Left_Click est relâchée
		$Sex_Choice.stop()
