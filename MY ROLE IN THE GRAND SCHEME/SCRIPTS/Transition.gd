extends Node2D

## Signal emitted when the transition has finished.
signal transition_finished

##
## Takes a screenshot, displays it, then starts an animation to fade it out.
## This is a coroutine; await it to pause until it finishes, in particular
## before making changes to the scene which might affect the screenshot.
##
func start_transition():
	Globals.hide_ui_layers()
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	Globals.show_ui_layers()
	$Sprite.texture = ImageTexture.create_from_image(img)
	$Animation.play("Fade")
	show()

func _on_animation_finished(_anim_name):
	transition_finished.emit()
	hide()
	$Sprite.texture = null
