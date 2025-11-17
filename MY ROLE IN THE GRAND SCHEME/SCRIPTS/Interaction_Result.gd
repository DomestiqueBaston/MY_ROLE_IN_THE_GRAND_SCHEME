extends Node2D

signal done

signal _search_done
var _search_confirm: bool

func _ready():
	for button: Button in [$Dialogue/Quit, $Combat/Quit, $Investigation/Quit]:
		button.mouse_entered.connect(_on_mouse_entered)
		button.mouse_exited.connect(_on_mouse_exited)
		button.pressed.connect(_on_quit_pressed)

	var yes: Button = $Combat/Chalk/Control/Report/Search_Body/Yes_No/Yes
	var no: Button = $Combat/Chalk/Control/Report/Search_Body/Yes_No/No

	yes.mouse_entered.connect(_on_mouse_entered)
	yes.mouse_exited.connect(_on_mouse_exited)
	yes.pressed.connect(_on_yes_pressed)
	no.mouse_entered.connect(_on_mouse_entered)
	no.mouse_exited.connect(_on_mouse_exited)
	no.pressed.connect(_on_no_pressed)

func _on_mouse_entered():
	if not (Globals.leave_sound.playing or Globals.hover_sound.playing):
		Globals.hover_sound.play()

func _on_mouse_exited():
	if not (Globals.hover_sound.playing or Globals.leave_sound.playing):
		Globals.leave_sound.play()

func _on_quit_pressed():
	Globals.valid_sound.play()
	await Globals.valid_sound.finished
	done.emit()

##
## Waits for the player to click on the Yes or No button, then returns true for
## Yes or false for No.
##
func ask_to_search_body() -> bool:
	await _search_done
	return _search_confirm

func _on_yes_pressed():
	_search_confirm = true
	_search_done.emit()

func _on_no_pressed():
	_search_confirm = false
	_search_done.emit()
