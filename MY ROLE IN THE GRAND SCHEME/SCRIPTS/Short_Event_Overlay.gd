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
## Display a message telling the player whether his run-away attempt has failed
## or succeeded.
##
func show_run_away_message(success: bool):
	$Overlays/Misc/Announces/Run_Away/Player_Failure.visible = not success
	$Overlays/Misc/Announces/Run_Away/Player_Success.visible = success
	$Overlays/Misc/Announces/Run_Away.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Run_Away.hide()

##
## Displays a message telling the player that his reputation has gotten better
## (higher = true) or worse (higher = false).
##
func show_rep_message(higher: bool):
	$Overlays/Misc/Announces/Reputation/Lower_Rep.visible = not higher
	$Overlays/Misc/Announces/Reputation/Higher_Rep.visible = higher
	$Overlays/Misc/Announces/Reputation.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Reputation.hide()

##
## Displays a message telling the player that he is being attacked by an NPC.
##
func show_attack_message(npc: NpcCard):
	var is_minion = npc.category == NpcCard.NpcCategory.MINION
	if is_minion:
		$Overlays/Misc/Announces/Combat/Minion_Attack.show()
	else:
		$Overlays/Misc/Announces/Combat/NPC_Attack.show()
	$Overlays/Misc/Announces/Combat.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Combat.hide()
	if is_minion:
		$Overlays/Misc/Announces/Combat/Minion_Attack.hide()
	else:
		$Overlays/Misc/Announces/Combat/NPC_Attack.hide()

##
## Displays a message telling the player that he and an NPC both survived an
## attack, and he can now question the NPC.
##
func show_do_not_kill_message():
	$Overlays/Misc/Announces/Combat/Do_Not_Kill.show()
	$Overlays/Misc/Announces/Combat.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Combat.hide()
	$Overlays/Misc/Announces/Combat/Do_Not_Kill.hide()

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
## Displays an overlay where the player attempts to break in to some location.
## Returns the cards that have been dragged to the interaction zone when the
## player clicks on the button. 
##
func attempt_break_in() -> Array[Card]:
	$Overlays/Interaction_Run_Away_Break_In.enabled = true
	var player = GameState.player
	$Overlays/Interaction_Run_Away_Break_In.start_break_in(
		player.get_mastery_cards(), player.get_fallback_cards())
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
## Displays an overlay where the player attempts to run away before a combat.
## Returns the cards that have been dragged to the interaction zone when the
## player clicks on the button. 
##
func attempt_run_away() -> Array[Card]:
	$Overlays/Interaction_Run_Away_Break_In.enabled = true
	var player = GameState.player
	$Overlays/Interaction_Run_Away_Break_In.start_run_away(
		player.get_mastery_cards(), player.get_fallback_cards())
	$Overlays/Interaction_Run_Away_Break_In/Title/Run_Away.show()
	$Overlays/Interaction_Run_Away_Break_In.show()
	await _appear()
	await $Overlays/Interaction_Run_Away_Break_In.done
	await _disappear()
	$Overlays/Interaction_Run_Away_Break_In.hide()
	$Overlays/Interaction_Run_Away_Break_In/Title/Run_Away.hide()
	$Overlays/Interaction_Run_Away_Break_In.enabled = false
	return $Overlays/Interaction_Run_Away_Break_In.get_cards_played()

##
## Displays a dialog asking the player whether he wants to run away. Returns
## true if he does.
##
func confirm_run_away() -> bool:
	$Overlays/Run_Away_Break_In/Announces/Run_Away.show()
	$Overlays/Run_Away_Break_In.show()
	await _appear()
	await $Overlays/Run_Away_Break_In/Announces.done
	await _disappear()
	$Overlays/Run_Away_Break_In.hide()
	$Overlays/Run_Away_Break_In/Announces/Run_Away.hide()
	return $Overlays/Run_Away_Break_In/Announces.get_confirmed()

##
## Displays the visit to Doctor F dialog and waits for the player to confirm or
## cancel. Returns true if he confirmed.
##
func visit_doctor(price: int) -> bool:
	$Overlays/Care_Sheet.set_price(price)
	$Overlays/Care_Sheet.show()
	await _appear()
	await $Overlays/Care_Sheet.done
	await _disappear()
	$Overlays/Care_Sheet.hide()
	return $Overlays/Care_Sheet.get_confirmed()

##
## Displays the dialog for a visit to the dealer. The stock parameter is the
## number of doses available for purchase, the funds parameter is how much the
## player has to spend, and price is the price of a dose. Returns the number of
## doses the player bought.
##
func visit_dealer(stock: int, funds: int, price: int) -> int:
	if stock > 0:
		$Overlays/Rowena.reset(stock, funds, price)
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

##
## Displays an overlay indicating that an NPC has tried to run away before a
## dialogue (and possibly succeeded).
##
func show_npc_run(success: bool):
	$Overlays/Misc/Announces/Dialogue/NPC_Success.visible = success
	$Overlays/Misc/Announces/Dialogue/NPC_Failure.visible = not success
	$Overlays/Misc/Announces/Dialogue.show()
	$Overlays/Misc.show()
	await _appear()
	await $Overlays/Misc/Announces.done
	await _disappear()
	$Overlays/Misc.hide()
	$Overlays/Misc/Announces/Dialogue.hide()

##
## Displays an overlay showing the money, drugs and mastery cards the player is
## starting the game with.
##
func show_starting_hand():
	$Overlays/Income_Start/Starting_Hand.populate()
	$Overlays/Income_Start/Starting_Hand.show()
	$Overlays/Income_Start.show()
	await _appear()
	await $Overlays/Income_Start/Starting_Hand.done
	await _disappear()
	$Overlays/Income_Start.hide()
	$Overlays/Income_Start/Starting_Hand.hide()
	$Overlays/Income_Start/Starting_Hand.clear()

##
## Displays the dialog for managing the player's mastery cards. Returns true if
## the player may have made changes.
##
func manage_cards():
	$Overlays/Card_Management.start()
	$Overlays/Card_Management.show()
	await _appear()
	await $Overlays/Card_Management.done
	await _disappear()
	$Overlays/Card_Management.hide()
	$Overlays/Card_Management.reset()
	return $Overlays/Card_Management.get_confirmed()

##
## Displays the dialog managing open cases. Returns true if the current case
## has changed.
##
func manage_cases() -> bool:
	$Overlays/Case_Management.start()
	$Overlays/Case_Management.show()
	await _appear()
	await $Overlays/Case_Management.done
	await _disappear()
	$Overlays/Case_Management.hide()
	$Overlays/Case_Management.reset()
	return $Overlays/Case_Management.has_case_changed()

##
## Displays the results of a dialogue with an NPC.
##
func show_dialogue_result(got_info: bool):
	$Overlays/Interaction_Result/Dialogue/Chalk/Control/Report/Info.visible = got_info
	$Overlays/Interaction_Result/Dialogue/Chalk/Control/Report/No_Info.visible = not got_info
	$Overlays/Interaction_Result/Dialogue.show()
	$Overlays/Interaction_Result.show()
	await _appear()
	await $Overlays/Interaction_Result.done
	await _disappear()
	$Overlays/Interaction_Result.hide()
	$Overlays/Interaction_Result/Dialogue.hide()

##
## Displays the results of a combat with an NPC. If the NPC died, the player is
## given the option of searching the body (for money).
##
func show_combat_result(damage: GameState.CombatDamage, npc_state: GameState.NpcCombatState):
	$Overlays/Interaction_Result/Combat/Chalk/Control/Report/But_Player_Hit.visible = \
		damage == GameState.CombatDamage.HIT
	$Overlays/Interaction_Result/Combat/Chalk/Control/Report/But_Player_Critically_Hit.visible = \
		damage == GameState.CombatDamage.CRITICAL_HIT
	$Overlays/Interaction_Result/Combat/Chalk/Control/Report/Do_Not_Kill.visible = \
		npc_state == GameState.NpcCombatState.WILL_TALK
	$Overlays/Interaction_Result/Combat/Chalk/Control/Report/End_NPC_Alive.visible = \
		npc_state != GameState.NpcCombatState.DEAD
	$Overlays/Interaction_Result/Combat/Chalk/Control/Report/End_NPC_Dead.visible = \
		npc_state == GameState.NpcCombatState.DEAD
	$Overlays/Interaction_Result/Combat/Chalk/Control/Report/Search_Body.visible = \
		npc_state == GameState.NpcCombatState.DEAD
	$Overlays/Interaction_Result/Combat.show()
	$Overlays/Interaction_Result.show()
	await _appear()

	# if the player searches the NPC's body, he has a 25% chance of finding 100
	# units of money (+/- 10%) and a 25% chance of adding +1 Wan

	var search_result: Node = null

	if npc_state == GameState.NpcCombatState.DEAD:
		if await $Overlays/Interaction_Result.ask_to_search_body():
			var wan: int = 0
			var money: int = 0
			if randi() % 4 == 0:
				wan = 1
			if randi() % 4 == 0:
				money = roundi(100 * randf_range(0.9, 1.1))
			if money > 0:
				search_result = $Overlays/Interaction_Result/Combat/Chalk/Control/Report/Search_Body/Search_Result/If_Yes_Search_Money
				search_result.find_child("Money").text = str(money)
				search_result.find_child("And_Wan").visible = wan > 0
			else:
				search_result = $Overlays/Interaction_Result/Combat/Chalk/Control/Report/Search_Body/Search_Result/If_Yes_Search_No_Money
				search_result.find_child("But_Wan").visible = wan > 0
			if wan > 0:
				GameState.player.wanted += wan
		else:
			search_result = $Overlays/Interaction_Result/Combat/Chalk/Control/Report/Search_Body/Search_Result/If_No

	if search_result:
		search_result.show()

	await $Overlays/Interaction_Result.done
	await _disappear()

	$Overlays/Interaction_Result.hide()
	$Overlays/Interaction_Result/Combat.hide()

	if search_result:
		search_result.hide()

##
## Displays the results of an investigation, including whether it was a failure,
## a success, a critical failure or a critical success and, in the last case,
## how much money was found.
##
func show_investigation_result(success: bool, critical: bool, money: int = 0):
	var search_result: Node

	if success:
		if critical:
			search_result = $Overlays/Interaction_Result/Investigation/Chalk/Control/Positive_Report/Report/Search_Result/Critical_Success_Money
			search_result.find_child("Money").text = str(money)
		else:
			search_result = $Overlays/Interaction_Result/Investigation/Chalk/Control/Positive_Report/Report/Search_Result/Success
	else:
		if critical:
			search_result = $Overlays/Interaction_Result/Investigation/Chalk/Control/Positive_Report/Report/Search_Result/Critical_Failure
		else:
			search_result = $Overlays/Interaction_Result/Investigation/Chalk/Control/Positive_Report/Report/Search_Result/Failure

	search_result.show()

	$Overlays/Interaction_Result/Investigation.show()
	$Overlays/Interaction_Result.show()
	await _appear()
	await $Overlays/Interaction_Result.done
	await _disappear()
	$Overlays/Interaction_Result.hide()
	$Overlays/Interaction_Result/Investigation.hide()

	search_result.hide()
