extends Control

## Signal emitted when the player presses the quit button.
signal done

var _current_card: Card

func _ready():
	$Quit.pressed.connect(_on_pressed)
	$Quit.mouse_entered.connect(_on_mouse_entered)
	$Quit.mouse_exited.connect(_on_mouse_exited)

##
## Call this before displaying the dialog to populate it with information about
## the player's initial state (money, drugs and mastery cards).
##
func populate():
	var player: Player = GameState.player
	$Chalk/Money.text = str(player.get_money())
	$Chalk/Drug.text = str(player.get_drugs())
	for card in player.get_mastery_cards():
		$Cards.add_child(card)
	Globals.mouse_entered_card.connect(_on_mouse_entered_card)

##
## Be sure to call this when done with the dialog, to remove the player's
## mastery cards.
##
func clear():
	Globals.mouse_entered_card.disconnect(_on_mouse_entered_card)
	if _current_card:
		_current_card.set_highlighted(false)
		_current_card = null
	var card_count = $Cards.get_child_count()
	for i in card_count:
		$Cards.remove_child($Cards.get_child(card_count - 1 - i))

func _on_mouse_entered_card(card: Card):
	if _current_card:
		_current_card.set_highlighted(false)
	_current_card = card
	_current_card.set_highlighted(true)

func _on_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()
