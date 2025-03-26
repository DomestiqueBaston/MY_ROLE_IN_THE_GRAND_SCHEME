extends TextureButton


func _on_pressed() -> void:
	$"../Tv_Switch".play()
	$"../Line_Animation".visible = not $"../Line_Animation".visible
	$"../Interaction".visible = not $"../Interaction".visible
	#$"../Movies".visible = not $"../Movies".visible
	$"../Screen".visible = not $"../Screen".visible
