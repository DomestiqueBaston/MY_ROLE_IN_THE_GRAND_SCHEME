extends Node2D

@export var point1: Vector2:
	set(value):
		if $Line:
			$Line.points[0] = value

@export var point2: Vector2:
	set(value):
		if $Line:
			$Line.points[1] = value

func show_line():
	show()
	$Drag_Drop_Line_Animation.play("Appearance")

func hide_line():
	$Drag_Drop_Line_Animation.play("Disappearance")
	await $Drag_Drop_Line_Animation.animation_finished
	hide()
