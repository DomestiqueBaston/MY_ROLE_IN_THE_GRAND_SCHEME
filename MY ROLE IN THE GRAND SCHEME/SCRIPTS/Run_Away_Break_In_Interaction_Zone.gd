extends TextureRect


@onready var interaction_collider = $"../../Colliders/Interaction_Area/Interaction_Collider"

var is_hovering = false

func _ready():
	visible = false

func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	var collider_global_position = interaction_collider.global_position
	var shape = interaction_collider.shape


	var rect = Rect2(collider_global_position - shape.extents, shape.extents * 2)
	if rect.has_point(mouse_position):
		if not is_hovering:
			if $"../../../Shared_Interface_Sounds/Leave".playing == true or $"../../../Shared_Interface_Sounds/Hover".playing == true:
				pass
			else:
				$"../../../Shared_Interface_Sounds/Hover".play()
			is_hovering = true
			visible = true
	else:
		if is_hovering:
			if $"../../../Shared_Interface_Sounds/Hover".playing == true or $"../../../Shared_Interface_Sounds/Leave".playing == true:
				pass
			else:
				$"../../../Shared_Interface_Sounds/Leave".play()
			is_hovering = false
			visible = false
