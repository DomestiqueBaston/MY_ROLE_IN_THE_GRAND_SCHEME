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

func start(result: Case.SolutionResult, money: int = 0, cards: int = 0):
	var control: Control
	match result:
		Case.SolutionResult.WRONG:
			control = $Income_Fail
		Case.SolutionResult.HALF_RIGHT:
			control = $Income_Half
		Case.SolutionResult.RIGHT:
			control = $Income

	if result != Case.SolutionResult.WRONG:
		var money_label: RichTextLabel = control.get_node("Chalk/Money_Cards/Money")
		var cards_label: RichTextLabel = control.get_node("Chalk/Money_Cards/Cards")
		money_label.text = str(money)
		cards_label.text = str(cards)

	control.show()

func clear(result: Case.SolutionResult):
	match result:
		Case.SolutionResult.WRONG:
			$Income_Fail.hide()
		Case.SolutionResult.HALF_RIGHT:
			$Income_Half.hide()
		Case.SolutionResult.RIGHT:
			$Income.hide()

func _on_ok_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()
