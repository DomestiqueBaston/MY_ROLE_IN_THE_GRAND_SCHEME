class_name Card extends Node2D

var _is_expanded = true

func _ready():
	$Card_Animations.play("RESET")
	z_index = 0

func get_card_name():
	return $Card_Mask/Card_BG/Card_Text/Card_Name.text

#
# Modifies the opacity of both the card and its shadow.
#
func set_opacity(opacity: float):
	$Card_Mask.modulate = opacity
	if $Card_Shadow.material:
		$Card_Shadow.material.set_shader_parameter(
			"shadow_color", Color(0, 0, 0, opacity * 0.3))

func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.popup_card_menu.emit(event.global_position, self)
	elif event.is_action_pressed("Left_Click"):
		if _is_expanded:
			$Card_Animations.play("Reduce_Card")
		else:
			$Card_Animations.play("Expand_Card")
		_is_expanded = not _is_expanded

func _on_card_collider_mouse_entered():
	$Shadow_Animations.play("Shadow_On")
	if Globals.card_exited_sound.playing:
		Globals.card_exited_sound.stop()
	if not Globals.card_entered_sound.playing:
		Globals.card_entered_sound.play()
	z_index = 1


func _on_card_collider_mouse_exited():
	$Shadow_Animations.play("Shadow_Off")
	if not Globals.card_entered_sound.playing:
		Globals.card_exited_sound.play()
	z_index = 0
