extends TextureButton


func _on_pressed() -> void:
	$"../White_Noise".playing = not $"../White_Noise".playing
	$"../Tv_Switch".play()
	$"../Line_Animation".visible = not $"../Line_Animation".visible
	$"../Interaction".visible = not $"../Interaction".visible
	$"../Screen".visible = not $"../Screen".visible
