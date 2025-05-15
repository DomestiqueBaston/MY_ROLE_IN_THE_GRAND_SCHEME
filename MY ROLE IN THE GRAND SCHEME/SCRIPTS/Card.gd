class_name Card extends Node2D

@export var auto_select = true

var _is_expanded = true
var _is_current = false

func _ready():
	$Card_Animations.play("RESET")
	if auto_select:
		$Card_Mask/Card_Collider.mouse_entered.connect(_on_card_collider_mouse_entered)
		$Card_Mask/Card_Collider.mouse_exited.connect(_on_card_collider_mouse_exited)

func get_card_name():
	return $Card_Mask/Card_BG/Card_Text/Card_Name.text

func get_size():
	return Vector2i(
		$Card_Mask.texture.get_width() / $Card_Mask.hframes,
		$Card_Mask.texture.get_height() / $Card_Mask.vframes)

func expand_or_reduce():
	if _is_expanded:
		$Card_Animations.play("Reduce_Card")
	else:
		$Card_Animations.play("Expand_Card")
	_is_expanded = not _is_expanded

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
		#var parent = get_parent()
		#if parent:
			#var last_child = parent.get_child(-1)
			#if last_child != self:
				#if last_child is Card:
					#parent.move_child(last_child, 0)
				#move_to_front()
		z_index = 1
		Globals.set_current_card.emit(self)
	else:
		$Shadow_Animations.play("Shadow_Off")
		if not Globals.card_entered_sound.playing:
			Globals.card_exited_sound.play()
		z_index = 0

#
# Modifies the opacity of both the card and its shadow.
#
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
			get_viewport().set_input_as_handled()
			if event.double_click:
				Globals.card_double_click.emit(event.global_position, self)
			else:
				Globals.card_left_click.emit(event.global_position, self)

func _on_card_collider_mouse_entered():
	set_current(true)

func _on_card_collider_mouse_exited():
	set_current(false)
