@tool
class_name Card extends Node2D

enum CardType {
	COMBAT,
	INVESTIGATION,
	DIALOGUE,
	ABSTRACT,
	OBJECT,
	LOCATION,
	NPC
}

enum CombatType {
	NONE,
	SPECIAL,
	RUN_AWAY
}

enum InvestigationType {
	NONE,
	SPECIAL,
	BREAK_IN
}

enum LocationStatus {
	NONE,
	CLOSED,
	CRIME_SCENE
}

enum NpcHealth {
	NONE,
	GOOD,
	AVERAGE,
	LOW
}

enum NpcStatus {
	NONE,
	JAIL,
	DEAD,
	DISAPPEARED,
	MINION
}

@export var card_name: String = "Card Name":
	set(value):
		card_name = value
		if $Card_Mask/Card_BG/Card_Text/Card_Name:
			$Card_Mask/Card_BG/Card_Text/Card_Name.text = card_name

@export var description: String = "Short card description.":
	set(value):
		description = value
		if $Card_Mask/Card_BG/Card_Text/Card_Name:
			$Card_Mask/Card_BG/Card_Text/Card_Description.text = description

@export var card_type: CardType:
	set(value):
		card_type = value
		_update_card_type()

@export var combat_type: CombatType:
	set(value):
		combat_type = value
		_update_card_type()

@export var investigation_type: InvestigationType:
	set(value):
		investigation_type = value
		_update_card_type()

@export var location_status: LocationStatus:
	set(value):
		location_status = value
		_update_card_type()

@export var npc_health: NpcHealth:
	set(value):
		npc_health = value
		_update_card_type()

@export var npc_status: NpcStatus:
	set(value):
		npc_status = value
		_update_card_type()

@export var is_object_evidence: bool:
	set(value):
		is_object_evidence = value
		_update_card_type()

##
## true if the card is in the reserve, false if it is in play. If the card is
## the reserve, it cannot be reduced, and the reserve decides which card to
## highlight as the mouse moves, not the card itself.
##
@export var is_stacked: bool:
	set(value):
		if is_stacked != value:
			# because a stacked card's Z index is incremented when highlighted
			if _is_highlighted:
				if is_stacked:
					z_index -= 1
				else:
					z_index += 1
			is_stacked = value
			for location in _pins:
				_pins[location].visible = not is_stacked

@export var opacity: float = 1:
	set(value):
		opacity = value
		_update_opacity()

var _is_highlighted: bool = false
var _is_expanded: bool = true
var _pins = {}

func _ready():
	set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		for location in _pins:
			_pins[location].global_position = get_pin_position(location)

func _update_card_type():
	match card_type:
		CardType.COMBAT:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = true
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Card_Color/Combat/Special.visible = (combat_type == CombatType.SPECIAL)
			$Card_Mask/Card_BG/Card_Color/Combat/Run_Away.visible = (combat_type == CombatType.RUN_AWAY)
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.INVESTIGATION:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = true
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation/Special.visible = (investigation_type == InvestigationType.SPECIAL)
			$Card_Mask/Card_BG/Card_Color/Investigation/Break_In.visible = (investigation_type == InvestigationType.BREAK_IN)
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.DIALOGUE:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = true
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.ABSTRACT:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = true
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.OBJECT:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = true
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = is_object_evidence
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.LOCATION:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = true
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = (location_status == LocationStatus.CLOSED)
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = (location_status == LocationStatus.CRIME_SCENE)
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false
			$Card_Mask/Card_BG/Minion_Status.visible = false

		CardType.NPC:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = false
			$Card_Mask/Card_BG/Card_Color/Npc.visible = true
			$Card_Mask/Card_BG/Card_Color/Npc/No_Info.visible = (npc_health == NpcHealth.NONE)
			$Card_Mask/Card_BG/Card_Color/Npc/Good_Health.visible = (npc_health == NpcHealth.GOOD)
			$Card_Mask/Card_BG/Card_Color/Npc/Average_Health.visible = (npc_health == NpcHealth.AVERAGE)
			$Card_Mask/Card_BG/Card_Color/Npc/Low_Health.visible = (npc_health == NpcHealth.LOW)
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = false
			$Card_Mask/Card_BG/Crime_Scene_Status.visible = false
			$Card_Mask/Card_BG/Jail_Status.visible = (npc_status == NpcStatus.JAIL)
			$Card_Mask/Card_BG/Dead_Status.visible = (npc_status == NpcStatus.DEAD)
			$Card_Mask/Card_BG/Disappeared_Status.visible = (npc_status == NpcStatus.DISAPPEARED)
			$Card_Mask/Card_BG/Minion_Status.visible = (npc_status == NpcStatus.MINION)

func get_size() -> Vector2i:
	return Vector2i(
		$Card_Mask.texture.get_width() / $Card_Mask.hframes,
		$Card_Mask.texture.get_height() / $Card_Mask.vframes)

func get_pin_position(which: int) -> Vector2:
	return $Pin_Locators.get_child(which).global_position

##
## Expands (true) or reduces (false) the card.
##
func set_expanded(expanded: bool):
	if _is_expanded != expanded:
		if expanded:
			$Card_Animations.play("Expand_Card")
		else:
			$Card_Animations.play("Reduce_Card")
		_is_expanded = expanded

##
## Expands the card if it is reduced, reduces it if it is expanded.
##
func expand_or_reduce():
	set_expanded(not _is_expanded)

##
## Specifies whether or not the card is highlighted. When a card is highlighted,
## its Z index is increased and its shadow is displayed. Sounds are played when
## a card's highlight state changes.
##
func set_highlighted(highlighted: bool):
	if _is_highlighted == highlighted:
		return

	if highlighted:
		if is_stacked:
			$Card_Shadow.position = Vector2(0, 0)
			$Card_Shadow.show()
			z_index += 1
		else:
			$Shadow_Animations.play("Shadow_On")
			move_to_front()
		if Globals.card_exited_sound.playing:
			Globals.card_exited_sound.stop()
		if not Globals.card_entered_sound.playing:
			Globals.card_entered_sound.play()
	else:
		if is_stacked:
			$Card_Shadow.hide()
			$Card_Shadow.position = Vector2(-2, -4)
			z_index -= 1
		else:
			$Shadow_Animations.play("Shadow_Off")
		if not Globals.card_entered_sound.playing:
			Globals.card_exited_sound.play()

	_is_highlighted = highlighted

func _update_opacity():
	$Card_Mask.modulate.a = opacity
	if $Card_Shadow.material:
		$Card_Shadow.material.set_shader_parameter(
			"shadow_color", Color(0, 0, 0, opacity * 0.3))

func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if $Card_Animations.is_playing():
			pass
		elif event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			Globals.card_right_click.emit(event.global_position, self)
		elif event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if not event.double_click:
				Globals.card_left_click.emit(event.global_position, self)
			elif not is_stacked:
				expand_or_reduce()

func _on_card_collider_mouse_entered():
	if not is_stacked:
		Globals.mouse_entered_card.emit(self)

func _on_card_collider_mouse_exited():
	if not is_stacked:
		Globals.mouse_exited_card.emit(self)

##
## Modifies the appearance of the card to show it is being dragged.
##
func start_drag():
	if _is_expanded:
		$Card_Animations.play("Drag_Expanded_Card_Appearance")
	else:
		$Card_Animations.play("Drag_Reduced_Card_Appearance")
	$Shadow_Animations.play("Shadow_Off")
	z_index += 1

##
## Resets the appearance of the card after a call to start_drag().
##
func stop_drag():
	if _is_expanded:
		$Card_Animations.play("Drag_Expanded_Card_Disappearance")
	else:
		$Card_Animations.play("Drag_Reduced_Card_Disappearance")
	$Shadow_Animations.play("Shadow_On")
	z_index -= 1

func add_pin(pin: Pin, location: Pin.Location):
	_pins[location] = pin
	pin.global_position = get_pin_position(location)

func remove_pin(location: Pin.Location):
	_pins.erase(location)

func move_pin(from: Pin.Location, to: Pin.Location):
	var pin = _pins[from]
	_pins.erase(from)
	_pins[to] = pin
	pin.global_position = get_pin_position(to)

func find_closest_unused_pin(global_pos: Vector2) -> int:
	var min_dist2 = -1
	var min_pin = -1

	for i in $Pin_Locators.get_child_count():
		if i not in _pins:
			var locator = $Pin_Locators.get_child(i)
			var dist2 = global_pos.distance_squared_to(locator.global_position)
			if min_dist2 < 0 or min_dist2 > dist2:
				min_dist2 = dist2
				min_pin = i

	return min_pin
