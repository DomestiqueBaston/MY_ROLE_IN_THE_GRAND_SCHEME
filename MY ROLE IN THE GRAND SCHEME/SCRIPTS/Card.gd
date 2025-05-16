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
	DISAPPEARED
}

@export var card_name: String = "Card Name":
	set(value):
		card_name = value
		_update_card_type()

@export var description: String = "Short card description.":
	set(value):
		description = value
		_update_card_type()

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

@export var is_location_closed: bool:
	set(value):
		is_location_closed = value
		_update_card_type()

@export var opacity: float = 1:
	set(value):
		opacity = value
		_update_opacity()

var _is_expanded = true

func _ready():
	$Card_Animations.play("RESET")

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
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false

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
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false

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
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false

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
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false

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
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false

		CardType.LOCATION:
			$Card_Mask/Card_BG/Card_Color/Combat.visible = false
			$Card_Mask/Card_BG/Card_Color/Investigation.visible = false
			$Card_Mask/Card_BG/Card_Color/Dialogue.visible = false
			$Card_Mask/Card_BG/Card_Color/Abstract.visible = false
			$Card_Mask/Card_BG/Card_Color/Object.visible = false
			$Card_Mask/Card_BG/Card_Color/Location.visible = true
			$Card_Mask/Card_BG/Card_Color/Npc.visible = false
			$Card_Mask/Card_BG/Evidence.visible = false
			$Card_Mask/Card_BG/Closed_Status.visible = is_location_closed
			$Card_Mask/Card_BG/Jail_Status.visible = false
			$Card_Mask/Card_BG/Dead_Status.visible = false
			$Card_Mask/Card_BG/Disappeared_Status.visible = false

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
			$Card_Mask/Card_BG/Jail_Status.visible = (npc_status == NpcStatus.JAIL)
			$Card_Mask/Card_BG/Dead_Status.visible = (npc_status == NpcStatus.DEAD)
			$Card_Mask/Card_BG/Disappeared_Status.visible = (npc_status == NpcStatus.DISAPPEARED)

func get_card_name():
	return card_name

func get_size():
	return Vector2i(
		$Card_Mask.texture.get_width() / $Card_Mask.hframes,
		$Card_Mask.texture.get_height() / $Card_Mask.vframes)

##
## Returns true if the Card is parented to a CardStack. If that is the case, the
## CardStack is responsible for deciding which card is highlighted. If not, the
## Card tracks the mouse position itself and emits signals when the mouse enters
## and exits the card's bounding box.
##
func is_stacked():
	return get_parent() is CardStack

##
## Expands the card if it is reduced, reduces it if it is expanded.
##
func expand_or_reduce():
	if _is_expanded:
		$Card_Animations.play("Reduce_Card")
	else:
		$Card_Animations.play("Expand_Card")
	_is_expanded = not _is_expanded

##
## Specifies whether or not the card is highlighted. When a card is highlighted,
## its Z index is set to 1 and its shadow is displayed. Sounds are played when a
## card's highlight state changes.
##
func set_highlighted(highlighted: bool):
	if highlighted:
		$Shadow_Animations.play("Shadow_On")
		if Globals.card_exited_sound.playing:
			Globals.card_exited_sound.stop()
		if not Globals.card_entered_sound.playing:
			Globals.card_entered_sound.play()
		z_index = 1
	else:
		$Shadow_Animations.play("Shadow_Off")
		if not Globals.card_entered_sound.playing:
			Globals.card_exited_sound.play()
		z_index = 0

func _update_opacity():
	$Card_Mask.modulate.a = opacity
	if $Card_Shadow.material:
		$Card_Shadow.material.set_shader_parameter(
			"shadow_color", Color(0, 0, 0, opacity * 0.3))

func _on_card_collider_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			get_viewport().set_input_as_handled()
			Globals.card_right_click.emit(event.global_position, self)
		elif event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if not event.double_click:
				get_viewport().set_input_as_handled()
				Globals.card_left_click.emit(event.global_position, self)
			elif not is_stacked():
				get_viewport().set_input_as_handled()
				expand_or_reduce()

func _on_card_collider_mouse_entered():
	if not is_stacked():
		Globals.mouse_entered_card.emit(self)

func _on_card_collider_mouse_exited():
	if not is_stacked():
		Globals.mouse_exited_card.emit(self)
