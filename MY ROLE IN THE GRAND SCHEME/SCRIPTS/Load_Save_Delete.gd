extends Node2D


func _on_load_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$"../../On_Off".play("Disappearance")
	await $"../../On_Off".animation_finished


func _on_save_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$"../../On_Off".play("Disappearance")
	await $"../../On_Off".animation_finished


func _on_delete_pressed():
	Globals.cancel_sound.play()
	await Globals.cancel_sound.finished
	$"../../On_Off".play("Disappearance")
	await $"../../On_Off".animation_finished


func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()


func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

#Il y a un truc pas super chouette, il faudra revoir ça :
func _on_item_list_mouse_entered():
	Globals.hover_sound.play()

func _on_item_list_mouse_exited():
	Globals.leave_sound.play()

func _on_item_list_item_selected(_index: int):
	Globals.valid_sound.play()
	
