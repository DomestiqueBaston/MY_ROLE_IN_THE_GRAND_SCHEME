extends Control

# Référence au CollisionShape2D
@onready var interaction_collider = $"../../Colliders/Trash_Collider/Trash"
@onready var trash_normal = $Trash_Normal
@onready var trash_hover = $Trash_Hover

# Variable pour suivre si la souris est sur le collider
var is_hovering = false

func _ready():
	trash_normal.visible = true
	trash_hover.visible = false

	# start processing when we actually need this thing
	set_process(false)

func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	var collider_global_position = interaction_collider.global_position
	var shape = interaction_collider.shape
	
	# Ignore les détections si le noeud parent est invisible
	if not get_node("../..").visible:
		return


	var rect = Rect2(collider_global_position - shape.extents, shape.extents * 2)
	if rect.has_point(mouse_position):
		if not is_hovering:
			$"../../Trash_Open".play()
			is_hovering = true
			trash_normal.visible = false
			trash_hover.visible = true
	else:
		if is_hovering:
			$"../../Trash_Close".play()
			is_hovering = false
			trash_normal.visible = true
			trash_hover.visible = false
