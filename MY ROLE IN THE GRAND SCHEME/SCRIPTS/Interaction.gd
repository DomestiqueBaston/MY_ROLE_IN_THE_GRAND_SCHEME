extends Node2D

## This script is used in two different but similar contexts: with Interaction
## (a standalone scene), and with a subscene of the Short_Event_Overlay scene
## (for run-away and break-in interactions). That is why a number of UI elements
## are exported properties: because not all UI elements are present in both
## contexts.

## Areas containing cards (piles and the interaction zone), and the overlays
## used to highlight each area. Keys and values in the Dictionary are all
## NodePaths: each key is a SizedNode2D containing cards, and its value is the
## corresponding overlay to be shown or hidden as needed.
@export var card_area_overlays: Dictionary

## The node containing cards dropped in the interaction zone.
@export var interaction_cards: SizedNode2D

## The maximum number of cards that the interaction zone can hold.
@export var max_card_count: int = 3

## The minimum number of cards in the interaction zone required before the
## button is enabled.
@export var min_card_count: int = 1

## The button that can be pressed when cards are ready.
@export var the_button: BaseButton

## The line used to illustrate drag & drop operations (an instance of
## Drag_Drop_Line.tscn).
@export var drag_drop_line: Node2D

## Optional Top_Bar scene containing the menu bar and player stats.
@export var top_bar: Node

## Optional TV screen that plays during the interaction.
@export var tv_screen: Node2D

## Optional Bottom_Left_Info scene showing information about the current card.
@export var info_box: Node

## If false, the scene does not process input events.
@export var enabled: bool = true:
	set(value):
		if enabled != value:
			enabled = value
			if is_node_ready():
				if enabled:
					_enable()
				else:
					_disable()

## Signal emitted when the interaction is done.
signal done

## Signal emitted when the player selects Settings in the menu.
signal settings

## Signal emitted when the user selects Quit in the menu.
signal quit

# highlighted card
var _current_card: Card

# has a card been clicked on, or is it being dragged?
enum DragState {
	NONE,		# nothing is going on
	CLICKED,	# a card has been clicked but is not being dragged yet
	DRAGGING	# a card is being dragged
}
var _drag_state: DragState = DragState.NONE

# card position in local coordinates when dragging began
var _drag_local_init_pos: Vector2

# card position in global coordinates when dragging began
var _drag_global_init_pos: Vector2

# where the user clicked, in global coordinates, to initiate dragging
var _drag_click_pos: Vector2

# overlay highlighting the card pile concerned by drag & drop
var _highlighted_overlay: CanvasItem

# overlay to highlight the name of each card pile
var _area_overlays = {}

# cards that have been dragged to the interaction zone, and which piles they
# came from
var _cards_played: Dictionary

# what kind of interaction is in progress
var _interaction_type: GameState.InteractionType = GameState.InteractionType.NONE

# which card to show info about when the mouse is not over a card
var _default_info_card: Card

# only one of these card types can be played in a dialogue interaction
const _dialog_question_types = [
	Card.CardType.OBJECT, Card.CardType.LOCATION, Card.CardType.NPC
]

func _ready():
	for area in card_area_overlays:
		_area_overlays[get_node(area)] = get_node(card_area_overlays[area])

	if top_bar:
		top_bar.settings.connect(func(): settings.emit())
		top_bar.quit.connect(func(): quit.emit())

	if info_box:
		info_box.clear()

	if enabled:
		_enable()
	else:
		_disable()

	if the_button:
		the_button.pressed.connect(_end_interaction)

	tree_exiting.connect(_detach_cards)

func _enable():
	Globals.mouse_entered_card.connect(_mouse_entered_card)
	Globals.mouse_exited_card.connect(_mouse_exited_card)
	Globals.card_left_click.connect(_click_on_card)
	_enable_disable_button()
	set_process_input(true)

func _disable():
	if Globals.mouse_entered_card.is_connected(_mouse_entered_card):
		Globals.mouse_entered_card.disconnect(_mouse_entered_card)
	if Globals.mouse_exited_card.is_connected(_mouse_exited_card):
		Globals.mouse_exited_card.disconnect(_mouse_exited_card)
	if Globals.card_left_click.is_connected(_click_on_card):
		Globals.card_left_click.disconnect(_click_on_card)
	if the_button:
		the_button.disabled = true
	set_process_input(false)

func _input(event: InputEvent):
	if _drag_state == DragState.DRAGGING:
		if event is InputEventMouseMotion:
			_drag(event.global_position)
		elif event is InputEventMouseButton and not event.pressed:
			_stop_drag(event.global_position)
			_drag_state = DragState.NONE
		elif event.is_action_pressed("Escape"):
			get_viewport().set_input_as_handled()
			_abort_drag()
			_drag_state = DragState.NONE
	elif _drag_state == DragState.CLICKED:
		if event is InputEventMouseMotion:
			if _start_drag():
				Globals.dragging = true
				_drag_state = DragState.DRAGGING
			else:
				_drag_state = DragState.NONE
		elif event is InputEventMouseButton and not event.pressed:
			_drag_state = DragState.NONE

func _mouse_entered_card(card: Card):
	# if this is a sub-scene, ignore signals from other cards in the scene
	if _drag_state == DragState.NONE and card != _current_card and is_ancestor_of(card):
		if _current_card:
			_current_card.set_highlighted(false)
		card.set_highlighted(true)
		_current_card = card
		if info_box:
			info_box.show_card(_current_card)

func _mouse_exited_card(card: Card):
	# if this is a sub-scene, ignore signals from other cards in the scene
	if _drag_state == DragState.NONE and card == _current_card:
		card.set_highlighted(false)
		_current_card = null
		if info_box:
			if _default_info_card:
				info_box.show_card(_default_info_card)
			else:
				info_box.clear()

func _click_on_card(global_pos: Vector2, card: Card):
	# if this is a sub-scene, ignore signals from other cards in the scene
	if is_ancestor_of(card):
		_mouse_entered_card(card)
		_drag_state = DragState.CLICKED
		_drag_click_pos = global_pos

func _start_drag() -> bool:
	_drag_local_init_pos = _current_card.position
	_drag_global_init_pos = _current_card.global_position
	_current_card.start_drag()

	# turn on the drag & drop line that connects the initial and current
	# mouse positions

	drag_drop_line.point1 = _drag_click_pos
	drag_drop_line.point2 = _drag_click_pos
	drag_drop_line.show_line()
	Globals.push_mouse_cursor(Globals.MouseCursor.CIRCLE)

	# highlight the pile the card belongs to

	var pile = _cards_played.get(_current_card, _current_card.get_parent())
	_highlighted_overlay = _area_overlays[pile]
	_highlighted_overlay.show()

	return true

func _drag(global_pos: Vector2):

	# move the card and the endpoint of the drag & drop line

	_current_card.global_position = \
		(_drag_global_init_pos + (global_pos - _drag_click_pos)).round()
	drag_drop_line.point2 = global_pos

	# highlight the interaction zone when the mouse enters it, with a sound
	# effect

	if _cards_played.size() < max_card_count:
		var overlay = _area_overlays[interaction_cards]
		var in_interaction_zone = _is_in_sized_node2d(interaction_cards, global_pos)
		if overlay.visible != in_interaction_zone:
			overlay.visible = in_interaction_zone
			if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
				if in_interaction_zone:
					Globals.hover_sound.play()
				else:
					Globals.leave_sound.play()

func _abort_drag():
	Globals.pop_mouse_cursor()
	drag_drop_line.hide_line()
	var card = _current_card
	var tween = create_tween()
	tween.tween_property(card, "position", _drag_local_init_pos, 0.15)
	await tween.finished
	_stuff_to_do_when_drag_ends(card)

func _stop_drag(global_pos: Vector2):

	# what card area did the user drop the card over?

	var new_parent = _get_card_area_at(global_pos)
	if not new_parent:
		_abort_drag()
		return

	# if the card is in the interaction area, it can only be dropped back on its
	# original pile

	if _current_card in _cards_played:
		if new_parent != _cards_played[_current_card]:
			_abort_drag()
			return
		_cards_played.erase(_current_card)
		_current_card.reparent(new_parent, false)

	# if the card is in a pile, it can only be dropped in the interaction area,
	# but only until it is full, and not if there is already a card of the same
	# type

	else:
		if not (new_parent == interaction_cards
				and _is_card_droppable(_current_card)):
			_abort_drag()
			return
		_cards_played[_current_card] = _current_card.get_parent()
		_current_card.reparent(interaction_cards)

	Globals.pop_mouse_cursor()
	_stuff_to_do_when_drag_ends(_current_card)
	_enable_disable_button()
	_layout_played_cards()

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	drag_drop_line.hide_line()
	if dragged_card:
		dragged_card.stop_drag()
	Globals.dragging = false
	_area_overlays[interaction_cards].hide()
	_highlighted_overlay.hide()

func _get_card_area_at(global_pos: Vector2) -> Node2D:
	for area in _area_overlays:
		if _is_in_sized_node2d(area, global_pos):
			return area
	return null

func _is_in_sized_node2d(node: SizedNode2D, global_pos: Vector2):
	var local_rect = Rect2(Vector2(0, 0), node.size)
	var local_pos = node.to_local(global_pos)
	return local_rect.has_point(local_pos)

func _layout_played_cards():
	var card_count = _cards_played.size()
	if card_count == 0:
		return

	const margin = 2
	var tween = create_tween().set_parallel()
	var center = interaction_cards.size * 0.5
	var pos

	if card_count & 1:
		pos = Vector2(center.x - Card.size.x * 0.5, 0)
	else:
		pos = Vector2(center.x + margin * 0.5, 0)

	if card_count > 1:
		@warning_ignore("integer_division")
		pos.x -= (card_count / 2) * (Card.size.x + margin)

	for card: Card in _cards_played:
		if card.position != pos:
			tween.tween_property(card, "position", pos, 0.1)
		pos.x += Card.size.x + margin

#
# Removes cards from the scene without deleting them, because the Player holds
# references to them.
#
func _detach_cards():
	for card in $Cards.find_children("*", "", true, false):
		if card is Card:
			card.get_parent().remove_child(card)

#
# Returns true if the given card can be dropped in the interaction zone.
#
func _is_card_droppable(card: Card) -> bool:

	# the number of cards is always limited to max_card_count

	if _cards_played.size() >= max_card_count:
		return false

	# you can never play two cards of the same type

	for other_card in _cards_played:
		if other_card.get_card_type() == card.get_card_type():
			match card.get_card_type():
				Card.CardType.COMBAT:
					if other_card.combat_type == card.combat_type:
						return false
				Card.CardType.INVESTIGATION:
					if other_card.investigation_type == card.investigation_type:
						return false
				_:
					return false

	# in a dialogue, there can only be one object, location or NPC card

	if (_interaction_type == GameState.InteractionType.DIALOGUE
		and card.get_card_type() in _dialog_question_types):
			for other_card in _cards_played:
				if other_card.get_card_type() in _dialog_question_types:
					return false

	return true

func _enable_disable_button():
	if the_button:
		the_button.disabled = not _is_card_combo_ok()

func _is_card_combo_ok() -> bool:
	match _interaction_type:
		GameState.InteractionType.DIALOGUE:
			var ok = true
			var got_question = false
			var card_types = []
			for card in _cards_played:
				var card_type = card.get_card_type()
				if card_type in card_types:
					ok = false
					break
				if card_type in _dialog_question_types:
					if got_question:
						ok = false
						break
					got_question = true
				card_types.append(card_type)
			return ok and Card.CardType.DIALOGUE in card_types

		GameState.InteractionType.INVESTIGATION:
			var inv_count = 0
			var inv_special_count = 0
			var abstract_count = 0
			for card in _cards_played:
				if card is InvestigationCard:
					match card.investigation_type:
						InvestigationCard.InvestigationType.NORMAL:
							inv_count += 1
						InvestigationCard.InvestigationType.SPECIAL:
							inv_special_count += 1
				elif card is AbstractCard:
					abstract_count += 1
			return inv_count == 1 and inv_special_count <= 1 and abstract_count <= 1

		GameState.InteractionType.BREAK_IN:
			var break_in_count = 0
			var abstract_count = 0
			for card in _cards_played:
				if card is InvestigationCard:
					break_in_count += 1
				elif card is AbstractCard:
					abstract_count += 1
			return ((break_in_count + abstract_count == 0) or
					(break_in_count == 1 and abstract_count <= 1))

		_:
			return _cards_played.size() >= min_card_count

##
## Starts an investigation. A done() signal is emitted when it finishes.
##
func start_investigation(mastery_cards: Array[Card], fallback_cards: Array[Card]):
	for card in mastery_cards:
		if card is AbstractCard or card is InvestigationCard:
			$Cards/Mastery.add_child(card)
	for card in fallback_cards:
		$Cards/Fallback.add_child(card)
	_start_interaction(GameState.InteractionType.INVESTIGATION)

##
## Starts a break-in. A done() signal is emitted when it finishes.
##
func start_break_in(mastery_cards: Array[Card], fallback_cards: Array[Card]):
	for card in mastery_cards:
		if card is AbstractCard:
			$Cards/Mastery.add_child(card)
	for card in fallback_cards:
		$Cards/Fallback.add_child(card)
	_start_interaction(GameState.InteractionType.BREAK_IN)

##
## Starts a dialogue. A done() signal is emitted when it finishes.
##
func start_dialogue(
	npc: NpcCard, mastery_cards: Array[Card], fallback_cards: Array[Card]):
	for card: Card in GameState.get_current_case().get_revealed_cards():
		if card == npc:
			continue
		card.set_expanded(true, false)
		if card.find_links(Link.Type.GUILT):
			$Cards/Evidence.add_child(card)
		else:
			match card.get_card_type():
				Card.CardType.OBJECT:
					$Cards/Objects.add_child(card)
				Card.CardType.LOCATION:
					$Cards/Locations.add_child(card)
				Card.CardType.NPC:
					$Cards/NPCs.add_child(card)

	for card in mastery_cards:
		if card is AbstractCard or card is DialogueCard:
			$Cards/Mastery.add_child(card)

	for card in fallback_cards:
		$Cards/Fallback.add_child(card)

	_start_interaction(GameState.InteractionType.DIALOGUE, npc)

##
## After an interaction has finished, returns the cards that were played, that
## is, that were dragged into the interaction zone.
##
func get_cards_played() -> Array[Card]:
	var cards: Array[Card]
	cards.assign(_cards_played.keys())
	return cards

func _start_interaction(type: GameState.InteractionType, npc: NpcCard = null):
	_cards_played.clear()
	_interaction_type = type
	if tv_screen:
		if type == GameState.InteractionType.DIALOGUE and npc:
			tv_screen.set_dialogue_npc(npc)
			if info_box:
				_default_info_card = npc
				info_box.show_card(npc)
		tv_screen.set_interaction_type(type)

#
# Resets the scene and emits a done() signal when an interaction finishes. The
# reset is important, because this scene may be instanced within another scene,
# meaning _ready() may only be called once. 
#
func _end_interaction():
	_interaction_type = GameState.InteractionType.NONE
	_default_info_card = null
	_current_card = null
	_detach_cards()
	done.emit()
