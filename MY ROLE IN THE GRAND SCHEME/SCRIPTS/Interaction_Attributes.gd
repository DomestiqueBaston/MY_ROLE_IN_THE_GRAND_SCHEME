class_name InteractionAttributes extends RefCounted

## Class for handling changes to the player's primary and secondary attributes
## during an interaction. PHY, MEN and HEA changes are temporary; Emo and Add
## changes are made permanent by calling apply_changes_to_player().

var PHY: int
var MEN: int
var HEA: int
var Emo: int
var Add: int

var _location_data = preload("res://JSON/OBJECT_LOCATION/Location.json").data
var _investigation_data = preload("res://JSON/INTERACTION/Investigation.json").data
var _abstract_data = preload("res://JSON/INTERACTION/Abstract.json").data

##
## The attributes are initialized from the player's actual attributes.
##
func _init():
	var player = GameState.player
	PHY = player.physical
	MEN = player.mental
	HEA = player.health
	Emo = player.emotion
	Add = player.addiction

##
## Applies any emotion or addiction changes that have been made to the
## player's actual attributes.
##
func apply_changes_to_player():
	var player = GameState.player
	player.emotion = Emo
	player.addiction = Add

##
## Retrieves bonus/malus information from the given card and applies it to any
## mentioned attributes (PHY, Emo, etc.). No changes are actually applied to the
## player until apply_changes_to_player() is called.
##
## If the card is an abstract card from the player's mastery deck, it is removed
## from the deck and deleted!
##
func play_card(card: Card):
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
	for key in bonus_malus:
		if not key in self:
			continue
		var before = self[key]
		match key:
			"PHY", "MEN":
				self[key] += bonus_malus[key]
			"HEA":
				HEA = mini(GameState.player.max_health, HEA + bonus_malus[key])
			"Emo", "Add":
				var attr_value = self[key]
				var dict_value = bonus_malus[key]
				if dict_value is String and dict_value.begins_with("mag"):
					var change = dict_value.substr(3).to_int()
					if change > 0:
						if attr_value >= 0:
							attr_value += change
						else:
							attr_value -= change
					elif change < 0:
						if attr_value > 0:
							attr_value = maxi(0, attr_value + change)
						elif attr_value < 0:
							attr_value = mini(0, attr_value - change)
				else:
					attr_value += dict_value as int
				self[key] = attr_value
		var after = self[key]
		print("card bonus/malus: %s %s" % [key, after - before])

##
## Returns true if the named attribute satisfies the given condition. For
## example, if attr is "MEN" and condition is ">1", returns true if MEN > 1.
##
func is_condition_met(attr: String, condition: String) -> bool:
	var op = condition.substr(0, 1)
	var value = condition.substr(1).to_int()
	match op:
		'>':
			return self[attr] > value
		'<':
			return self[attr] > value
		'=':
			return self[attr] == value
		'!':
			return self[attr] != value
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
