class_name SaveLoadTools

## This class implements saving and loading of objects to and from a JSON file.
## A class that needs save/load support must have an entry in the class Enum,
## provide a function for allocating a new instance in _allocate_object(), and
## implement the following methods:
##
## get_referenced_objects()
##
## Returns an Array of other objects referenced by the instance.
##
## get_json_dict()
##
## Returns a Dictionary containing all the information about the instance that
## needs to be saved. Dictionary values must all be either simple Variants that
## can be represented in JSON format (no vectors, no objects) or, for the
## objects returned by get_referenced_objects(), objects IDs returned by
## SaveLoadTools.get_object_id().
##
## restore(dict, catalog)
##
## Restores an instance to its saved state, given the dictionary that was
## returned by get_json_dict() and reloaded from the JSON file, and a catalog of
## other objects that were saved to the JSON file and recreated. The catalog
## maps object IDs (those that were returned by SaveLoadTools.get_object_id()
## and saved to the dictionary) to new object instances of the appropriate type.
## Note that those objects are not guaranteed to have been restored to their
## saved state yet; you cannot rely on the contents of the referenced objects.
##
## SaveLoadTools provides two static methods: save_to_json_dict() saves an
## object and any other objects it references to a JSON dictionary, and
## restore_from_json_dict() recreates the object and those it references.

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
	return str(obj.get_instance_id())

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

	# allocate this object

	var obj = _allocate_object(dict["class"] as Class)
	var catalog = {
		dict["id"]: obj
	}

	# allocate referenced objects

	for ref_id in dict.get("refs", {}):
		var ref_dict = dict.refs[ref_id]
		catalog[ref_id] = _allocate_object(ref_dict["class"] as Class)

	# restore all objects from the JSON dictionary and object catalog

	obj.restore(dict["props"], catalog)
	for ref_id in dict.get("refs", {}):
		var ref_dict = dict.refs[ref_id]
		catalog[ref_id].restore(ref_dict["props"], catalog)

	return obj

static func _allocate_object(type: Class) -> Object:
	match type:
		Class.PLAYER:
			return Player.allocate()
		Class.ABSTRACT_CARD:
			return AbstractCard.allocate()
		Class.COMBAT_CARD:
			return CombatCard.allocate()
		Class.DIALOGUE_CARD:
			return DialogueCard.allocate()
		Class.INVESTIGATION_CARD:
			return InvestigationCard.allocate()
		Class.LOCATION_CARD:
			return LocationCard.allocate()
		Class.OBJECT_CARD:
			return ObjectCard.allocate()
		Class.NPC_CARD:
			return NpcCard.allocate()
		Class.PIN:
			return Pin.allocate()
		Class.LINK:
			return Link.allocate()
		Class.CASE:
			return Case.allocate()
		Class.GAME_STATE:
			return GameState.allocate()
		_:
			return null
