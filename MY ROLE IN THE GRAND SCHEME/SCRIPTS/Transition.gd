extends Node2D

signal transition_finished

var _next_scene: PackedScene

func start_transition_to(scene: PackedScene):
	var img = get_viewport().get_texture().get_image()
	img.flip_y()
	$Sprite.texture = ImageTexture.create_from_image(img)
	_next_scene = scene
	$Animation.play("Fade")
	show()

func _on_animation_finished(_anim_name):
	transition_finished.emit()
	get_tree().change_scene_to_packed(_next_scene)
