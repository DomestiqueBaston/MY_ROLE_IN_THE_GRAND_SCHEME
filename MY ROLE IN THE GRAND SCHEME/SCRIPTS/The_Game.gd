extends Node2D

@onready var _title_screen: Node
@onready var _option_menu_scene = preload("res://SCENES/Option_Menu.tscn")
@onready var _settings_scene = preload("res://SCENES/Settings.tscn")
@onready var _credits_scene = preload("res://SCENES/Credits.tscn")
@onready var _language_scene = preload("res://SCENES/Language.tscn")
@onready var _tutorial_scene = preload("res://SCENES/Tutorial.tscn")
@onready var _char_gen_scene = preload("res://SCENES/Character_Generation.tscn")
@onready var _main_scene = preload("res://SCENES/Main_V2.tscn")
@onready var _interaction_scene = preload("res://SCENES/Interaction.tscn")
@onready var _quit_scene = preload("res://SCENES/Quit.tscn")
@onready var _death_scene = preload("res://SCENES/Death.tscn")

#
# Player attributes saved before leaving the main scene and restored afterward,
# so we can detect if they have changed, i.e. by an interaction.
#
var _saved_PHY = -1
var _saved_MEN = -1
var _saved_HEA = -1

func _ready():
	_title_screen = $Active_Scene/Title_Screen
	_title_screen.next.connect(_go_to_option_menu)
	GameState.interaction_started.connect(_on_interaction_started)
	GameState.died.connect(_on_death)

func _replace_scene(new_scene: PackedScene) -> Node:

	# save game before closing main scene

	for child in $Active_Scene.get_children():
		if child.scene_file_path == _main_scene.resource_path:
			GameState.save_game()
			_save_player_attrs()

	# take a screenshot that will fade to reveal the new scene

	await $Transition.start_transition()

	# delete the current scene

	for child in $Active_Scene.get_children():
		if child == _title_screen:
			# the title screen fades out before deleting itself
			child.fade_out()
			_title_screen = null
		else:
			child.free()

	# instantiate the new scene

	var node = new_scene.instantiate()
	$Active_Scene.add_child(node)
	return node

func _go_to_option_menu():
	var option_menu = await _replace_scene(_option_menu_scene)
	option_menu.button_pressed.connect(_on_option_button_pressed)

func _on_option_button_pressed(button: StringName):
	match button:
		&"Settings":
			_go_to_settings()
		&"Credits":
			_go_to_credits()
		&"Language":
			_go_to_language_scene()
		&"Tutorial":
			_go_to_tutorial()
		&"New_Game":
			_go_to_char_gen()
		&"Continue":
			_continue_game()
		&"Quit":
			_quit()

func _go_to_settings():
	var is_playing = \
		$Active_Scene.get_child(0).scene_file_path != _option_menu_scene.resource_path
	var settings = await _replace_scene(_settings_scene)
	await settings.done
	if settings.is_confirmed():
		Globals.save_settings()
	if is_playing:
		_continue_game()
	else:
		_go_to_option_menu()

func _go_to_credits():
	var credits = await _replace_scene(_credits_scene)
	await credits.done
	_go_to_option_menu()

func _go_to_language_scene():
	var language = await _replace_scene(_language_scene)
	await language.done
	_go_to_option_menu()

func _go_to_tutorial():
	var tutorial = await _replace_scene(_tutorial_scene)
	await tutorial.done
	_go_to_option_menu()

func _go_to_char_gen():
	if GameState.player.health > 0:
		var ok = await Globals.dialog_overlay.ask_for_confirmation(true)
		if not ok:
			return
	var new_game = await _replace_scene(_char_gen_scene)
	new_game.confirm_pressed.connect(_start_game)
	new_game.cancel_pressed.connect(_go_to_option_menu)

func _start_game():
	GameState.start_game()
	_continue_game()

func _continue_game():
	var interaction = GameState.get_current_interaction()
	if interaction in [
			GameState.InteractionType.NONE, GameState.InteractionType.BREAK_IN]:
		var main = await _replace_scene(_main_scene)
		_check_player_attrs()
		var case = GameState.get_current_case()
		if case:
			main.populate(case)
		main.settings.connect(_go_to_settings)
		main.quit.connect(_go_to_option_menu)
		if interaction == GameState.InteractionType.BREAK_IN:
			GameState.resume_break_in()
	else:
		_on_interaction_started()

func _on_interaction_started():
	var interaction_scene = await _replace_scene(_interaction_scene)
	interaction_scene.done.connect(_on_interaction_ended)
	interaction_scene.settings.connect(_go_to_settings)
	interaction_scene.quit.connect(_go_to_option_menu)

	match GameState.get_current_interaction():
		GameState.InteractionType.INVESTIGATION:
			interaction_scene.start_investigation(
				GameState.player.get_mastery_cards(),
				GameState.player.get_fallback_cards())
		GameState.InteractionType.DIALOGUE:
			interaction_scene.start_dialogue(
				GameState.get_current_interaction_npc(),
				GameState.player.get_mastery_cards(),
				GameState.player.get_fallback_cards())

func _on_interaction_ended():
	var interaction_scene = $Active_Scene.get_child(0)
	await GameState.end_interaction(interaction_scene.get_cards_played())
	_continue_game()

func _save_player_attrs():
	_saved_PHY = GameState.player.physical
	_saved_MEN = GameState.player.mental
	_saved_HEA = GameState.player.health

func _check_player_attrs():
	if _saved_PHY < 0:
		return
	if GameState.player.physical != _saved_PHY:
		GameState.physical_changed.emit()
	if GameState.player.mental != _saved_MEN:
		GameState.mental_changed.emit()
	if GameState.player.health != _saved_HEA:
		GameState.health_changed.emit()

func _quit():
	await _replace_scene(_quit_scene)
	await $Transition.transition_finished
	get_tree().quit()

func _on_death():
	var death = await _replace_scene(_death_scene)
	await death.done
	GameState.end_game()
	_go_to_option_menu()
