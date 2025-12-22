extends Node2D

signal done

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

# the currently highlighted card
var _current_card: Card

# did the user click on OK (true) or cancel (false)?
var _confirmed: bool

@onready var _description: RichTextLabel = $Bottom_Left_Info_Long/Scroll_Interaction/Description

func _ready():
	$Buttons.ok.connect(_on_ok_pressed)
	$Buttons.cancel.connect(_on_cancel_pressed)

func start():
	var player: Player = GameState.player
	for card in player.get_mastery_cards():
		$Mastery_Cards.add_child(card)
	for card in player.get_discard_cards():
		$Pool_Cards.add_child(card)
	Globals.mouse_entered_card.connect(_on_card_entered)
	Globals.mouse_exited_card.connect(_on_card_exited)
	Globals.card_left_click.connect(_click_on_card)

func reset():
	Globals.mouse_entered_card.disconnect(_on_card_entered)
	Globals.mouse_exited_card.disconnect(_on_card_exited)
	Globals.card_left_click.disconnect(_click_on_card)
	_current_card = null
	for card in $Mastery_Cards.get_children():
		$Mastery_Cards.remove_child(card)
	for card in $Pool_Cards.get_children():
		$Pool_Cards.remove_child(card)

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
			_start_drag()
			_drag_state = DragState.DRAGGING
		elif event is InputEventMouseButton and not event.pressed:
			_drag_state = DragState.NONE

func _start_drag():
	_drag_local_init_pos = _current_card.position
	_drag_global_init_pos = _current_card.global_position
	_current_card.start_drag()

	$Drag_Drop_Line.point1 = _drag_click_pos
	$Drag_Drop_Line.point2 = _drag_click_pos
	$Drag_Drop_Line.show_line()

	Globals.push_mouse_cursor(Globals.MouseCursor.CIRCLE)
	Globals.dragging = true

func _stuff_to_do_when_drag_ends(dragged_card: Card):
	$Drag_Drop_Line.hide_line()
	if dragged_card:
		dragged_card.stop_drag()
	Globals.dragging = false
	Globals.pop_mouse_cursor()
	$Card_Management_BG/Right_Zone.hide()
	$Card_Management_BG/Left_Zone.hide()

func _drag(global_pos: Vector2):
	_current_card.global_position = \
		(_drag_global_init_pos + (global_pos - _drag_click_pos)).round()
	$Drag_Drop_Line.point2 = global_pos
	var zone = _get_card_area_at(global_pos)
	$Card_Management_BG/Right_Zone.visible = (zone == $Mastery_Cards)
	$Card_Management_BG/Left_Zone.visible = (zone == $Pool_Cards)

func _abort_drag():
	$Drag_Drop_Line.hide_line()
	var card = _current_card
	var tween = create_tween()
	tween.tween_property(card, "position", _drag_local_init_pos, 0.15)
	await tween.finished
	_stuff_to_do_when_drag_ends(card)

func _stop_drag(global_pos: Vector2):
	var ok = true

	# check whether the card is dropped on the other area (Mastery or Pool),
	# and enforce some constraints: the mastery deck can contain at most 10
	# cards, including at most 3 abstract cards, 2 combat cards, 2 special
	# combat cards, 2 dialogue cards, 2 investigation cards, 2 special
	# investigation cards, 2 break-in cards and 1 run-away card

	var new_parent = _get_card_area_at(global_pos)
	if new_parent == null or new_parent == _current_card.get_parent():
		ok = false
	elif new_parent == $Mastery_Cards:
		if $Mastery_Cards.get_child_count() >= 10:
			ok = false
		else:
			var count = 1
			var limit = 10
			match _current_card.get_card_type():
				Card.CardType.COMBAT:
					var combat_type = _current_card.combat_type
					for card in $Mastery_Cards.get_children():
						if card is CombatCard and card.combat_type == combat_type:
							count += 1
					limit = 1 if combat_type == CombatCard.CombatType.RUN_AWAY else 2
				Card.CardType.INVESTIGATION:
					var investigation_type = _current_card.investigation_type
					for card in $Mastery_Cards.get_children():
						if (card is InvestigationCard
							and card.investigation_type == investigation_type):
							count += 1
					limit = 2
				Card.CardType.DIALOGUE:
					for card in $Mastery_Cards.get_children():
						if card is DialogueCard:
							count += 1
					limit = 2
				Card.CardType.ABSTRACT:
					for card in $Mastery_Cards.get_children():
						if card is AbstractCard:
							count += 1
					limit = 3
			ok = (count <= limit)

	if ok:
		_current_card.reparent(new_parent, false)
		_stuff_to_do_when_drag_ends(_current_card)
	else:
		_abort_drag()

func _get_card_area_at(global_pos: Vector2) -> Node2D:
	if _is_in_sized_node2d($Pool_Cards, global_pos):
		return $Pool_Cards
	if _is_in_sized_node2d($Mastery_Cards, global_pos):
		return $Mastery_Cards
	return null

func _is_in_sized_node2d(node: SizedNode2D, global_pos: Vector2):
	var local_rect = Rect2(Vector2(0, 0), node.size)
	var local_pos = node.to_local(global_pos)
	return local_rect.has_point(local_pos)

func _click_on_card(global_pos: Vector2, card: Card):
	_on_card_entered(card)
	_drag_state = DragState.CLICKED
	_drag_click_pos = global_pos

func _on_card_entered(card: Card):
	if _drag_state != DragState.NONE:
		return
	if _current_card:
		_current_card.set_highlighted(false)
	_current_card = card
	if _current_card:
		_current_card.set_highlighted(true)
		_description.text = _current_card.get_info()
	else:
		_description.text = ""

func _on_card_exited(card: Card):
	if _drag_state != DragState.NONE:
		return
	if _current_card == card:
		_current_card.set_highlighted(false)
		_description.text = ""
		_current_card = null

func get_confirmed() -> bool:
	return _confirmed

func _on_ok_pressed():
	var player = GameState.player
	var mastery_cards = player.get_mastery_cards().duplicate()
	var discard_cards = player.get_discard_cards().duplicate()
	for card in mastery_cards:
		if card.get_parent() == $Pool_Cards:
			player.discard_mastery_card(card)
	for card in discard_cards:
		if card.get_parent() == $Mastery_Cards:
			player.undiscard_mastery_card(card)
	_confirmed = true
	done.emit()

func _on_cancel_pressed():
	_confirmed = false
	done.emit()
