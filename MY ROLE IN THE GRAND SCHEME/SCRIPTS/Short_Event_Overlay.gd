extends Node2D

## Signal emitted before a (modal) dialog is displayed. It is expected that the
## current scene will turn off input handling until the dialog finishes.
signal pre_dialog

## Signal emitted when a (modal) dialog finishes and has been hidden.
signal post_dialog

func _appear():
	pre_dialog.emit()
	show()
	$On_Off.play("Appearance")
	await $On_Off.animation_finished

func _disappear(skip_animation: bool = false):
	if skip_animation:
		$On_Off.play("RESET")
	else:
		$On_Off.play("Disappearance")
		await $On_Off.animation_finished
	hide()
	post_dialog.emit()

##
## Display a dialog prompting the player to choose how many hours he wants to
## sleep. Return 0 if he cancels.
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
## Display a message telling the player he has a lot of outstanding debts.
##
func show_bill_announcement():
	$Overlays/Misc/Announces/Bill.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Bill.hide()

##
## Display a message telling the player he has overcome his addiction or died.
##
func show_addiction_message(die: bool):
	$Overlays/Misc/Announces/Addiction_Crisis_Result/Failure.visible = die
	$Overlays/Misc/Announces/Addiction_Crisis_Result/Success.visible = not die
	$Overlays/Misc/Announces/Addiction_Crisis_Result.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Addiction_Crisis_Result.hide()

##
## Display a message telling the player he has had a nice dream or a nightmare.
##
func show_dream_message(nightmare: bool):
	$Overlays/Misc/Announces/Dreams/Nightmare.visible = nightmare
	$Overlays/Misc/Announces/Dreams/Dream.visible = not nightmare
	$Overlays/Misc/Announces/Dreams.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Dreams.hide()

##
## Display a dialog asking the player for a yes or no and return the answer.
##
func ask_for_confirmation(skip_anim_if_yes: bool = false) -> bool:
	$Overlays/Confirmation.show()
	await _appear()
	await $Overlays/Confirmation.done
	var result = $Overlays/Confirmation.get_answer()
	await _disappear(result and skip_anim_if_yes)
	$Overlays/Confirmation.hide()
	return result

##
## Displays the investigation center, where the player can select the current
## case, and waits for him to confirm or cancel.
##
func open_investigation_center():
	$Overlays/Investigation_Center.populate()
	$Overlays/Investigation_Center.show()
	await _appear()
	await $Overlays/Investigation_Center.done
	await _disappear()
	$Overlays/Investigation_Center.hide()

##
## Displays the office and waits for the player to click on OK.
##
func open_office():
	$Overlays/Office.show()
	await _appear()
	await $Overlays/Office.done
	await _disappear()
	$Overlays/Office.hide()

##
## Displays the "buy search warrant" dialog and waits for the player to confirm
## or cancel. Returns true if he confirmed.
##
func buy_search_warrant():
	$Overlays/Search_Warrant/Text_Buy.reset()
	$Overlays/Search_Warrant/Text_Buy.show()
	$Overlays/Search_Warrant/Text_Use.hide()
	$Overlays/Search_Warrant.show()
	await _appear()
	await $Overlays/Search_Warrant/Text_Buy.done
	await _disappear()
	$Overlays/Search_Warrant.hide()
	return $Overlays/Search_Warrant/Text_Buy.get_confirmed()
