extends Node2D

@onready var _title_screen: Node
@onready var _option_menu_scene = preload("res://SCENES/Option_Menu.tscn")
@onready var _new_game_scene = preload("res://SCENES/Character_Generation.tscn")
@onready var _main_scene = preload("res://SCENES/Main_V2.tscn")
@onready var _quit_scene = preload("res://SCENES/Quit.tscn")

func _ready():
	_title_screen = $Active_Scene/Title_Screen
	_title_screen.next.connect(_go_to_option_menu)

func _replace_scene(new_scene: PackedScene) -> Node:
	await $Transition.start_transition()
	for child in $Active_Scene.get_children():
		if child == _title_screen:
			child.fade_out()
			_title_screen = null
		else:
			child.queue_free()
	var node = new_scene.instantiate()
	$Active_Scene.add_child(node)
	return node

func _go_to_option_menu():
	var option_menu = await _replace_scene(_option_menu_scene)
	option_menu.button_pressed.connect(_on_option_button_pressed)

func _on_option_button_pressed(button: StringName):
	match button:
		&"New_Game":
			_go_to_new_game()
		&"Continue":
			_continue_game()
		&"Quit":
			_quit()

func _go_to_new_game():
	if GameState.player.health > 0:
		var ok = await $Short_Event_Overlay.ask_for_confirmation()
		if not ok:
			return
	var new_game = await _replace_scene(_new_game_scene)
	new_game.confirm_pressed.connect(_start_game)
	new_game.cancel_pressed.connect(_go_to_option_menu)

func _start_game():
	GameState.start_game()
	_continue_game()

func _continue_game():
	var main = await _replace_scene(_main_scene)
	main.quit.connect(_go_to_option_menu)

func _quit():
	await _replace_scene(_quit_scene)
	await $Transition.transition_finished
	get_tree().quit()
