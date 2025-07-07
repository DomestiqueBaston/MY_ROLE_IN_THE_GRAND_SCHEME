class_name SaveLoadTools

enum Class {
	PLAYER,
	ABSTRACT_CARD,
	COMBAT_CARD,
	DIALOGUE_CARD,
	INVESTIGATION_CARD,
	LOCATION_CARD,
	OBJECT_CARD,
	NPC_CARD,
	PIN,
	LINK,
	CASE,
	GAME_STATE
}

static func get_object_id(obj: Object) -> String:
	return "@*@%d" % obj.get_instance_id()

static func save_to_json_dict(obj: Object) -> Dictionary:
	var refs: Array[Object]
	_find_all_refs(refs, obj)

	var catalog = {}
	for ref in refs:
		catalog[get_object_id(ref)] = _make_json_dict(ref)

	var dict = _make_json_dict(obj)
	dict["id"] = get_object_id(obj)
	if not catalog.is_empty():
		dict["refs"] = catalog

	return dict

static func _make_json_dict(obj: Object) -> Dictionary:
	return {
		"class": obj.get_custom_class(),
		"props": obj.get_json_dict()
	}

static func _find_all_refs(refs: Array[Object], obj: Object):
	var obj_refs = obj.get_referenced_objects()
	for ref in obj_refs:
		if not ref in refs:
			refs.append(ref)
			_find_all_refs(refs, ref)

static func restore_from_json_dict(dict: Dictionary) -> Object:
	var obj = _restore_object(dict["class"], dict["props"])
	var catalog = {
		dict["id"]: obj
	}

	for ref_id in dict.get("refs", {}):
		var ref_dict = dict.refs[ref_id]
		catalog[ref_id] = _restore_object(ref_dict["class"], ref_dict["props"])

	obj.set_referenced_objects(dict["props"], catalog)
	for ref_id in dict.get("refs", {}):
		var ref_dict = dict.refs[ref_id]
		catalog[ref_id].set_referenced_objects(ref_dict["props"], catalog)

	return obj

static func _restore_object(type: Class, props: Dictionary) -> Object:
	match type:
		Class.PLAYER:
			return Player.restore(props)
		Class.ABSTRACT_CARD:
			return AbstractCard.restore(props)
		Class.COMBAT_CARD:
			return CombatCard.restore(props)
		Class.DIALOGUE_CARD:
			return DialogueCard.restore(props)
		Class.INVESTIGATION_CARD:
			return InvestigationCard.restore(props)
		Class.LOCATION_CARD:
			return LocationCard.restore(props)
		Class.OBJECT_CARD:
			return ObjectCard.restore(props)
		Class.NPC_CARD:
			return NpcCard.restore(props)
		Class.PIN:
			return Pin.restore(props)
		Class.LINK:
			return Link.restore(props)
		Class.CASE:
			return Case.restore(props)
		Class.GAME_STATE:
			return GameState.restore(props)
		_:
			return null
