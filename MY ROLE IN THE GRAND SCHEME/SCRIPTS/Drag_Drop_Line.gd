extends Node2D

# The endpoints are offset by half the maximum line width, because the line is
# actually extended that much.

# Note that the line's Z index is set to 3, so that it appears on top of
# everything else. A card selected in the reserve of the main scene has a Z
# index of 1, which is raised to 2 while it is being dragged, so a Z index of 3
# ensures that the drag & drop line is drawn on top of all cards.

const _half_width = Vector2(10, 10)

@export var point1: Vector2:
	set(value):
		if $Line:
			$Line.points[0] = to_local(value - _half_width)

@export var point2: Vector2:
	set(value):
		if $Line:
			$Line.points[1] = to_local(value - _half_width)

func show_line():
	show()
	$Drag_Drop_Line_Animation.play("Appearance")

func hide_line():
	$Drag_Drop_Line_Animation.play("Disappearance")
	await $Drag_Drop_Line_Animation.animation_finished
	hide()
