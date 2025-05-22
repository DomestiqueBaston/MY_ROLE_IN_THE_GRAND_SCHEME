extends TextureButton


func _ready():
	if $"../..".visible:
		$"../../Intercom".play()

func _on_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	$"../../Intercom".stop()
	$"../../../../On_Off".play("Disappearance")
	await $"../../../../On_Off".animation_finished

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()


func _on_on_off_animation_finished(_anim_name: StringName) -> void:
	await get_tree().create_timer(0.4).timeout
	$"../Screens".show()
