class_name Card extends Node2D

@export var anim_expand : String = "Expand_Card"  # Nom de l'animation pour agrandir
@export var anim_reduce : String = "Reduce_Card"  # Nom de l'animation pour réduire
@export var anim_reset : String = "RESET"  # Nom de l'animation pour réinitialiser

var _is_expanded = true

func _ready():
	$Card_Animations.play(anim_reset)

func get_card_name():
	return $Card_Mask/Card_BG/Card_Text/Card_Name.text

func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		get_viewport().set_input_as_handled()
		Globals.popup_card_menu.emit(event.global_position, self)
	elif event.is_action_pressed("Left_Click"):
		if _is_expanded:
			$Card_Animations.play(anim_reduce)
		else:
			$Card_Animations.play(anim_expand)
		_is_expanded = not _is_expanded

func _on_card_collider_mouse_entered():
	$Shadow_Animations.play("Shadow_On")
	$UI_Sounds/Go_Front.play()
	move_to_front()

func _on_card_collider_mouse_exited():
	$Shadow_Animations.play("Shadow_Off")
	$UI_Sounds/Go_Back.play()
