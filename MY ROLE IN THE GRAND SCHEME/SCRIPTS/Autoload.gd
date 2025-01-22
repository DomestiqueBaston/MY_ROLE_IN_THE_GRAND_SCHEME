extends Node

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Full_Screen"):
		var mode := DisplayServer.window_get_mode()
		var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_window else DisplayServer.WINDOW_MODE_WINDOWED)

	if event.is_action_pressed("Escape"):
		get_tree().quit()
