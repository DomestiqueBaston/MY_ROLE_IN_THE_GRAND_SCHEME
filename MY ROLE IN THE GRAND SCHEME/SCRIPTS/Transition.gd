extends Node2D

signal transition_finished

func start_transition():
	Globals.hide_ui_layers()
	# I'm not sure why, but the mouse cursor disappears after TWO frames
	await get_tree().process_frame
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	Globals.show_ui_layers()
	$Sprite.texture = ImageTexture.create_from_image(img)
	$Animation.play("Fade")
	show()

func _on_animation_finished(_anim_name):
	transition_finished.emit()
	hide()
	$Sprite.texture = null
