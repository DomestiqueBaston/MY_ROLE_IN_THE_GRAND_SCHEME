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
## Display a message telling the player whether his break-in attempt has failed
## or succeeded.
##
func show_break_in_message(success: bool):
	$Overlays/Misc/Announces/Break_In/Player_Failure.visible = not success
	$Overlays/Misc/Announces/Break_In/Player_Success.visible = success
	$Overlays/Misc/Announces/Break_In.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Break_In.hide()

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
## case, and waits for him to confirm or cancel. Returns true if he changed the
## current case.
##
func open_investigation_center()  -> bool:
	$Overlays/Investigation_Center.populate()
	$Overlays/Investigation_Center.show()
	await _appear()
	await $Overlays/Investigation_Center.done
	await _disappear()
	$Overlays/Investigation_Center.hide()
	return $Overlays/Investigation_Center.has_case_changed()

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
func buy_search_warrant() -> bool:
	$Overlays/Search_Warrant/Text_Buy.show()
	$Overlays/Search_Warrant.show()
	await _appear()
	await $Overlays/Search_Warrant/Text_Buy.done
	await _disappear()
	$Overlays/Search_Warrant.hide()
	$Overlays/Search_Warrant/Text_Buy.hide()
	return $Overlays/Search_Warrant/Text_Buy.get_confirmed()

##
## Displays the "use search warrant" dialog and waits for the player to confirm
## or cancel. Returns true if he confirmed.
##
func use_search_warrant() -> bool:
	$Overlays/Search_Warrant/Text_Use.show()
	$Overlays/Search_Warrant.show()
	await _appear()
	await $Overlays/Search_Warrant/Text_Use.done
	await _disappear()
	$Overlays/Search_Warrant.hide()
	$Overlays/Search_Warrant/Text_Use.hide()
	return $Overlays/Search_Warrant/Text_Use.get_confirmed()

##
## Displays a message telling the player he hasn't got the search warrant he
## needs.
##
func no_search_warrant():
	$Overlays/Search_Warrant/Text_No_Warrant.show()
	$Overlays/Search_Warrant.show()
	await _appear()
	await $Overlays/Search_Warrant/Text_No_Warrant.done
	await _disappear()
	$Overlays/Search_Warrant.hide()
	$Overlays/Search_Warrant/Text_No_Warrant.hide()

##
## Displays a dialog asking the player whether he wants to break in. Returns
## true if he does.
##
func confirm_break_in() -> bool:
	$Overlays/Run_Away_Break_In/Announces/Break_In.show()
	$Overlays/Run_Away_Break_In.show()
	await _appear()
	await $Overlays/Run_Away_Break_In/Announces.done
	await _disappear()
	$Overlays/Run_Away_Break_In.hide()
	$Overlays/Run_Away_Break_In/Announces/Break_In.hide()
	return $Overlays/Run_Away_Break_In/Announces.get_confirmed()

##
## Displays an overlay where the player attempts to break in to the given
## locations. Returns the cards that have been dragged to the interaction zone
## when the player clicks on the button. 
##
func attempt_break_in(location: LocationCard) -> Array[Card]:
	$Overlays/Interaction_Run_Away_Break_In.enabled = true
	var player = GameState.player
	$Overlays/Interaction_Run_Away_Break_In.start_break_in(
		location, player.get_mastery_cards(), player.get_fallback_cards())
	$Overlays/Interaction_Run_Away_Break_In/Title/Break_In.show()
	$Overlays/Interaction_Run_Away_Break_In.show()
	await _appear()
	await $Overlays/Interaction_Run_Away_Break_In.done
	await _disappear()
	$Overlays/Interaction_Run_Away_Break_In.hide()
	$Overlays/Interaction_Run_Away_Break_In/Title/Break_In.hide()
	$Overlays/Interaction_Run_Away_Break_In.enabled = false
	return $Overlays/Interaction_Run_Away_Break_In.get_cards_played()

##
## Displays the visit to Doctor F dialog and waits for the player to confirm or
## cancel. Returns true if he confirmed.
##
func visit_doctor() -> bool:
	$Overlays/Care_Sheet.reset()
	$Overlays/Care_Sheet.show()
	await _appear()
	await $Overlays/Care_Sheet.done
	await _disappear()
	$Overlays/Care_Sheet.hide()
	return $Overlays/Care_Sheet.get_confirmed()

##
## Displays the dialog for a visit to the dealer. The stock parameter is the
## number of doses available for purchase, and the funds parameter is how much
## the player has to spend. Returns the number of doses the player bought.
##
func visit_dealer(stock: int, funds: int) -> int:
	if stock > 0:
		$Overlays/Rowena.reset(stock, funds)
		$Overlays/Rowena.show()
		await _appear()
		await $Overlays/Rowena.done
		await _disappear()
		$Overlays/Rowena.hide()
		return $Overlays/Rowena.get_doses_purchased()
	else:
		$Overlays/Misc/Announces/Rowena_Absent.show()
		$Overlays/Misc.show()
		await _appear()
		await $Overlays/Misc/Announces.done
		await _disappear()
		$Overlays/Misc.hide()
		$Overlays/Misc/Announces/Rowena_Absent.hide()
		return 0

func show_player_improvement(direction: int, attr_name: StringName = StringName()):
	var ctrl: Control
	match attr_name:
		&"HEA":
			if direction > 0:
				ctrl = $Overlays/Player_Improvement/Informations/Positive_Health
			else:
				ctrl = $Overlays/Player_Improvement/Informations/Negative_Health
		&"PHY":
			if direction > 0:
				ctrl = $Overlays/Player_Improvement/Informations/Positive_Physic
			else:
				ctrl = $Overlays/Player_Improvement/Informations/Negative_Physic
		&"MEN":
			if direction > 0:
				ctrl = $Overlays/Player_Improvement/Informations/Positive_Mental
			else:
				ctrl = $Overlays/Player_Improvement/Informations/Negative_Mental
		_:
			if direction > 0:
				ctrl = $Overlays/Player_Improvement/Informations/Positive_Total
			elif direction < 0:
				ctrl = $Overlays/Player_Improvement/Informations/Negative_Total
			else:
				ctrl = $Overlays/Player_Improvement/Informations/Positive_And_Negative
	ctrl.show()
	$Overlays/Player_Improvement.show()
	await _appear()
	await $Overlays/Player_Improvement.done
	await _disappear()
	$Overlays/Player_Improvement.hide()
	ctrl.hide()

##
## Displays an overlay indicating that the given NPC is not there.
##
func show_npc_away(npc: NpcCard):
	$Overlays/Intercom/Interface/Screens/Away/NPC.text = npc.get_display_name()
	$Overlays/Intercom.show()
	await _appear()
	$Overlays/Intercom.start()
	await $Overlays/Intercom.done
	await _disappear()
	$Overlays/Intercom.stop()
	$Overlays/Intercom.hide()
