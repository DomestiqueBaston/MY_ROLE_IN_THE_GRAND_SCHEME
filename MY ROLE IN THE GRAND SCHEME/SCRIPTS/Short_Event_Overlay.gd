extends Node2D

func _ready():
	$On_Off.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String):
	if anim_name == "Disappearance":
		hide()

##
## Call this before doing anything else: it makes the overlay visible and plays
## an opening animation. It will hide itself automatically.
##
func appear():
	show()
	$On_Off.play("Appearance")

##
## Display a dialog prompting the player to choose how many hours he wants to
## sleep. Returns 0 if he cancels.
##
func choose_sleep_time() -> int:
	$Overlays/Sleep/Drawer_Names.reset()
	$Overlays/Sleep.show()
	await $Overlays/Sleep/Drawer_Names.done
	var result = $Overlays/Sleep/Drawer_Names.get_hours_chosen()
	$Overlays/Sleep.hide()
	return result

##
## Display a dialog telling the player he has a lot of outstanding debts.
##
func show_bill_announcement():
	$Overlays/Misc/Announces/Bill.show()
	$Overlays/Misc.show()
	await $Overlays/Misc/Announces.done
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Bill.hide()
