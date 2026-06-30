extends Node2D

signal done

func _ready():
	$Income/Quit.connect("mouse_entered", Globals.on_mouse_entered)
	$Income_Half/Quit.connect("mouse_entered", Globals.on_mouse_entered)
	$Income_Fail/Quit.connect("mouse_entered", Globals.on_mouse_entered)

	$Income/Quit.connect("mouse_exited", Globals.on_mouse_exited)
	$Income_Half/Quit.connect("mouse_exited", Globals.on_mouse_exited)
	$Income_Fail/Quit.connect("mouse_exited", Globals.on_mouse_exited)

	$Income/Quit.connect("pressed", _on_ok_pressed)
	$Income_Half/Quit.connect("pressed", _on_ok_pressed)
	$Income_Fail/Quit.connect("pressed", _on_ok_pressed)

func _get_income_control(result: Case.SolutionResult) -> Control:
	match result:
		Case.SolutionResult.WRONG:
			return $Income_Fail
		Case.SolutionResult.HALF_RIGHT:
			return $Income_Half
		Case.SolutionResult.RIGHT:
			return $Income
	return null

func start(result: Case.SolutionResult, money: int = 0, cards: Array[Card] = []):
	var control: Control = _get_income_control(result)

	if result != Case.SolutionResult.WRONG:
		var money_label: RichTextLabel = control.get_node("Chalk/Money_Cards/Money")
		var cards_label: RichTextLabel = control.get_node("Chalk/Money_Cards/Cards")
		var card_stack: CardStack = control.get_node("Cards")
		money_label.text = str(money)
		cards_label.text = str(cards.size())
		for card in cards:
			card_stack.add_child(card)

	control.show()

func clear(result: Case.SolutionResult):
	var control: Control = _get_income_control(result)
	control.hide()

	if result != Case.SolutionResult.WRONG:
		var card_stack: CardStack = control.get_node("Cards")
		while card_stack.get_child_count() > 0:
			card_stack.remove_child(card_stack.get_child(0))

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
