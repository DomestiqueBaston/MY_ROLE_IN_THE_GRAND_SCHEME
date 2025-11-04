class_name InteractionAttributes extends RefCounted

## Class for handling changes to the player's primary and secondary attributes
## during an interaction. PHY, MEN and HEA changes are temporary; Emo and Add
## changes are permanent.

var PHY: int
var MEN: int
var HEA: int

var _fallback_card_count: int
var _dice: int
var _npc_dice: int
var _last_emo_malus: int
var _unhandled_bonus_malus: Dictionary
var _unhandled_success_bonus: Array[Dictionary]
var _unhandled_failure_malus: Array[Dictionary]

var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
var _investigation_data = preload("res://JSON/INTERACTION/Investigation.json").data
var _abstract_data = preload("res://JSON/INTERACTION/Abstract.json").data
var _dialogue_data = preload("res://JSON/INTERACTION/Dialogue.json").data
var _combat_data = preload("res://JSON/INTERACTION/Combat.json").data

func _init():
	reset()

func reset():
	var player = GameState.player
	PHY = player.physical
	MEN = player.mental
	HEA = player.health
	_fallback_card_count = 0
	_dice = 0
	_npc_dice = 0
	_last_emo_malus = 0
	_unhandled_bonus_malus.clear()
	_unhandled_success_bonus.clear()
	_unhandled_failure_malus.clear()

##
## Retrieves bonus/malus information from the given card and applies it to any
## mentioned attributes (PHY, Emo, etc.).
##
## A malus of 1 is added for each card player where is_fallback is true.
##
## If is_fallback is false, and the card is an abstract card from the player's
## mastery deck, it is removed from the deck and deleted!
##
func play_card(card: Card, is_fallback: bool):
	match card.get_card_type():
		Card.CardType.LOCATION:
			var loc_info = _location_data[card.database_id]
			print("applying card: %s" % loc_info["name"])
			apply_bonus_malus(loc_info.get("bonus_malus", {}))

		Card.CardType.INVESTIGATION:
			var investigation_info = _investigation_data[card.database_id]
			print("applying card: %s" % investigation_info["name"])
			apply_bonus_malus(investigation_info.get("bonus_malus", {}))

		Card.CardType.ABSTRACT:
			var abstract_info = _abstract_data[card.database_id]
			print("applying card: %s" % abstract_info["name"])
			for entry in abstract_info.get("bonus_malus", []):
				var conditions = entry.get("conditions", "")
				if are_conditions_met(conditions):
					var effects = entry.get("effects", {})
					apply_bonus_malus(effects)
					break

		Card.CardType.DIALOGUE:
			var dialogue_info = _dialogue_data[card.database_id]
			print("applying card: %s" % dialogue_info["name"])
			for entry in dialogue_info.get("bonus_malus", []):
				var condition = entry.get("condition", {})
				var result = condition.get("result", "")
				var effects = entry.get("effects", {})
				if not effects.is_empty():
					if result == "success":
						_unhandled_success_bonus.append(effects)
					elif result == "failure":
						_unhandled_failure_malus.append(effects)

		Card.CardType.COMBAT:
			var combat_info = _combat_data[card.database_id]
			print("applying card: %s" % combat_info["name"])
			apply_bonus_malus(combat_info.get("bonus_malus", {}))

	if is_fallback:
		_fallback_card_count += 1
	elif card is AbstractCard:
		GameState.player.remove_mastery_card(card)

##
## Applies any number of bonus/malus changes from a dictionary of entries like
## "HEA": -1, or "Emo": "mag+1". Each entry's value can be either a number,
## which is simply added to the named attribute, or a string containing the word
## "mag" followed by a number. In the latter case, the number is added to the
## attribute's "magnitude": that is, if the number is positive, the magnitude
## increases (gets farther from zero); if the number is negative, the magnitude
## decreases (gets closer to zero).
##
func apply_bonus_malus(bonus_malus: Dictionary):
	var player = GameState.player
	for key in bonus_malus:
		var value = bonus_malus[key]
		var delta: int = 0
		match key:
			"PHY":
				delta = value
				PHY += delta
			"MEN":
				delta = value
				MEN += delta
			"HEA":
				delta = mini(value, player.max_health - HEA)
				HEA += delta
			"Emo":
				delta = _interpret_bonus_malus_value(player.emotion, value)
				if delta != 0:
					if player.emotion == 0 or signi(delta) == signi(player.emotion):
						_last_emo_malus = delta
					player.emotion += delta
			"Add":
				delta = _interpret_bonus_malus_value(player.addiction, value)
				player.addiction += delta
			"dice":
				delta = value
				_dice += delta
			"opponent_dice":
				delta = value
				_npc_dice += delta
			_:
				if key in _unhandled_bonus_malus:
					_unhandled_bonus_malus[key].append(value)
				else:
					_unhandled_bonus_malus[key] = [value]
		if delta != 0:
			print("card bonus/malus: %s %s" % [key, delta])

#
# Given a current attribute value and a bonus/malus value from the dictionary,
# returns the integer value that should be added to the attribute value.
#
func _interpret_bonus_malus_value(attr_value: int, dict_value) -> int:
	if dict_value is String and dict_value.begins_with("mag"):
		var delta = dict_value.substr(3).to_int()
		if delta >= 0:
			if attr_value >= 0:
				return delta
			else:
				return -delta
		else:
			if attr_value > 0:
				return maxi(delta, -attr_value)
			elif attr_value < 0:
				return mini(-delta, -attr_value)
			else:
				return 0
	else:
		return dict_value as int

##
## Returns true if the named attribute satisfies the given condition. For
## example, if attr is "MEN" and condition is ">1", returns true if MEN > 1.
##
func is_condition_met(attr: String, condition: String) -> bool:
	var attr_value: int
	match attr:
		"PHY":
			attr_value = PHY
		"MEN":
			attr_value = MEN
		"HEA":
			attr_value = HEA
		"Emo":
			attr_value = GameState.player.emotion
		"Add":
			attr_value = GameState.player.addiction
		"Wan":
			attr_value = GameState.player.wanted
		_:
			return false

	var test_op = condition.substr(0, 1)
	var test_value = condition.substr(1).to_int()
	match test_op:
		'>':
			return attr_value > test_value
		'<':
			return attr_value > test_value
		'=':
			return attr_value == test_value
		'!':
			return attr_value != test_value
		_:
			return false

##
## Returns true if all conditions in the given dictionary are met. That is, each
## entry in the dictionary is passed to is_condition_met().
##
func are_conditions_met(conditions: Dictionary) -> bool:
	for attr in conditions:
		if not is_condition_met(attr, conditions[attr]):
			return false
	return true

##
## Returns the final bonus/malus value to be applied, as determined by the
## cards that have been played.
##
func get_bonus_malus() -> int:
	if _last_emo_malus != 0:
		var other: Array = _unhandled_bonus_malus.get("other", [])
		if other.has("cancel_Emo_malus"):
			other.erase("cancel_Emo_malus")
			print("cancel malus: Emo %s" % (- _last_emo_malus))
			GameState.player.emotion -= _last_emo_malus
			_last_emo_malus = 0

	var bonus_malus = GameState.player.get_bonus_malus()

	if _fallback_card_count > 0:
		bonus_malus += _fallback_card_count
		print("fallback card malus: %s" % _fallback_card_count)

	if _dice != 0:
		bonus_malus += _dice
		print("dice bonus/malus: %s" % _dice)

	return bonus_malus

##
## Returns the bonus/malus to be applied to an NPC's roll of the dice, as
## determined by his wanted status and, in the case of a combat, by any
## combat cards' "opponent_dice" bonus/malus.
##
func get_npc_bonus_malus(npc: NpcCard) -> int:
	var bonus_malus: int = 0

	if npc.wanted > 1:
		print("NPC Wan malus: %s" % (npc.wanted - 1))
		bonus_malus += npc.wanted - 1

	if _npc_dice != 0:
		print("NPC dice bonus/malus: %s" % _npc_dice)
		bonus_malus += _npc_dice

	return bonus_malus

##
## Returns a Dictionary of bonus/malus effects that were found in the cards
## played but whose keys were not handled here. Each entry contains an array of
## effects for the given key.
##
## Dialogue cards have effects that depend on whether the dialogue was
## successful or not (success true or false).
##
func get_post_bonus_malus(success: bool = true) -> Dictionary:
	var conditional: Array[Dictionary]

	if success:
		conditional = _unhandled_success_bonus
	else:
		conditional = _unhandled_failure_malus

	if conditional.is_empty():
		return _unhandled_bonus_malus

	var ret = _unhandled_bonus_malus.duplicate(true)

	for dict in conditional:
		for key in dict:
			var value = dict[key]
			if key in ret:
				ret[key].append(value)
			else:
				ret[key] = [value]

	return ret
