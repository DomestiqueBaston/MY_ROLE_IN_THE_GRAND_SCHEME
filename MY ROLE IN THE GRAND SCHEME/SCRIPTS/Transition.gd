extends Node2D

signal transition_finished

func start_transition():
	Globals.hide_shader_overlay()
	var img = get_viewport().get_texture().get_image()
	Globals.show_shader_overlay()
	$Sprite.texture = ImageTexture.create_from_image(img)
	$Animation.play("Fade")
	show()

func _on_animation_finished(_anim_name):
	transition_finished.emit()
	hide()
