class_name Card extends Node2D

var _is_expanded = true
var _is_current = false

func _ready():
	$Card_Animations.play("RESET")

func get_card_name():
	return $Card_Mask/Card_BG/Card_Text/Card_Name.text

func get_size():
	return Vector2i(
		$Card_Mask.texture.get_width() / $Card_Mask.hframes,
		$Card_Mask.texture.get_height() / $Card_Mask.vframes)

##
## Returns true if the Card is parented to a CardStack. If that is the case, the
## CardStack is responsible for setting the current Card. If not, the Card does
## that itself by tracking the mouse position.
##
func is_stacked():
	return get_parent() is CardStack

##
## Expands the card if it is reduced, reduces it if it is expanded.
##
func expand_or_reduce():
	if _is_expanded:
		$Card_Animations.play("Reduce_Card")
	else:
		$Card_Animations.play("Expand_Card")
	_is_expanded = not _is_expanded

##
## Specifies whether or not the card is "current". Only the current card's
## shadow is displayed, and it is displayed on top of all others by setting its
## Z index to 1. Also, sounds are played when the status of cards changes.
##
func set_current(current: bool):
	if _is_current == current:
		return
	_is_current = current
	if current:
		$Shadow_Animations.play("Shadow_On")
		if Globals.card_exited_sound.playing:
			Globals.card_exited_sound.stop()
		if not Globals.card_entered_sound.playing:
			Globals.card_entered_sound.play()
		z_index = 1
		Globals.set_current_card.emit(self)
	else:
		$Shadow_Animations.play("Shadow_Off")
		if not Globals.card_entered_sound.playing:
			Globals.card_exited_sound.play()
		z_index = 0

##
## Modifies the opacity of both the card and its shadow.
##
func set_opacity(opacity: float):
	$Card_Mask.modulate = opacity
	if $Card_Shadow.material:
		$Card_Shadow.material.set_shader_parameter(
			"shadow_color", Color(0, 0, 0, opacity * 0.3))

func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			get_viewport().set_input_as_handled()
			Globals.card_right_click.emit(event.global_position, self)
		elif event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if not event.double_click:
				get_viewport().set_input_as_handled()
				Globals.card_left_click.emit(event.global_position, self)
			elif not is_stacked():
				get_viewport().set_input_as_handled()
				expand_or_reduce()

func _on_card_collider_mouse_entered():
	if not is_stacked():
		set_current(true)

func _on_card_collider_mouse_exited():
	if not is_stacked():
		set_current(false)
