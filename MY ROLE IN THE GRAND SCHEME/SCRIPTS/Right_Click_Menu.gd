extends Node2D

@export var popup_menu: PopupMenu


func _input(_event):
	if Input.is_action_pressed("Right_Click"):
		var position_globale = get_global_mouse_position()
		var rect = Rect2i(position_globale, popup_menu.size)
		Globals.cancel_sound.play()
		popup_menu.popup(rect)

	if Input.is_action_pressed("Left_Click"):
		Globals.valid_sound.play()
		popup_menu.hide()

# Il manque le code pour les sons de navigation dans le menu...
# Dernières nouvelles : il semble que cela soit fait exprès dans Godot,
# on n'y a accès "normalement" uniquement pour la navigation au clavier
# dans les menus.
