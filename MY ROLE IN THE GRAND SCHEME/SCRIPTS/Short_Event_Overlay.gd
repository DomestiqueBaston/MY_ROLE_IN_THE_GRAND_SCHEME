extends Node2D

func _appear():
	show()
	$On_Off.play("Appearance")
	await $On_Off.animation_finished

func _disappear():
	$On_Off.play("Disappearance")
	await $On_Off.animation_finished
	hide()

##
## Display a dialog prompting the player to choose how many hours he wants to
## sleep. Returns 0 if he cancels.
##
func choose_sleep_time() -> int:
	$Overlays/Sleep.reset()
	$Overlays/Sleep.show()
	await _appear()
	await $Overlays/Sleep.done
	var result = $Overlays/Sleep.get_hours_chosen()
	await _disappear()
	$Overlays/Sleep.hide()
	return result

##
## Display a dialog telling the player he has a lot of outstanding debts.
##
func show_bill_announcement():
	$Overlays/Misc/Announces/Bill.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Bill.hide()
