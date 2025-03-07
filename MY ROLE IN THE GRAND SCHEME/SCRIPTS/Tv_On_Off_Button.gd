extends Button


func _on_pressed() -> void:
	$"../Tv_Switch".play()
	$"../Illustration_Animation".visible = not $"../Illustration_Animation".visible
	$"../Screen".visible = not $"../Screen".visible
