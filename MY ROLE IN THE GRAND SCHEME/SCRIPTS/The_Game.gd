extends Node2D

@onready var _option_menu: PackedScene = preload("res://SCENES/Option_Menu.tscn")

func _ready():
	$Active_Scene/Title_Screen.next.connect(_go_to_option_menu)

func _go_to_option_menu():
	$Transition.start_transition()
	$Active_Scene.add_child(_option_menu.instantiate())
	$Active_Scene/Title_Screen.queue_free()
