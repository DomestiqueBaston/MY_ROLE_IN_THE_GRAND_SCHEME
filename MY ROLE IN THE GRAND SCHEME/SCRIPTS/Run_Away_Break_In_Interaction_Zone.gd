extends TextureRect

@onready var interaction_collider = $"../../Colliders/Interaction_Area/Interaction"
@onready var mastery_collider = $"../../Colliders/Mastery_Area/Mastery"
@onready var fallback_collider = $"../../Colliders/Fallback_Area/Fallback"

@onready var mastery_zone = $"../Mastery_Zone"
@onready var fallback_zone = $"../Fallback_Zone"
@onready var interaction_zone = $"../Interaction_Zone"

var is_hovering = false

func _ready():
	mastery_zone.visible = false
	fallback_zone.visible = false
	visible = false

func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	var hovering = false

	if _is_mouse_over(interaction_collider, mouse_position):
		hovering = true
		interaction_zone.visible = true
		mastery_zone.visible = false
		fallback_zone.visible = false
	elif _is_mouse_over(mastery_collider, mouse_position):
		hovering = true
		mastery_zone.visible = true
		interaction_zone.visible = false
		fallback_zone.visible = false
	elif _is_mouse_over(fallback_collider, mouse_position):
		hovering = true
		fallback_zone.visible = true
		interaction_zone.visible = false
		mastery_zone.visible = false
	else:
		interaction_zone.visible = false
		mastery_zone.visible = false
		fallback_zone.visible = false

	if hovering and not is_hovering:
		if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
			Globals.hover_sound.play()
		is_hovering = true
	elif not hovering and is_hovering:
		if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
			Globals.leave_sound.play()
		is_hovering = false

func _is_mouse_over(collider, mouse_position):
	if collider != null:
		var collider_global_position = collider.global_position
		var shape = collider.shape
		var rect = Rect2(collider_global_position - shape.extents, shape.extents * 2)
		return rect.has_point(mouse_position)
	return false
