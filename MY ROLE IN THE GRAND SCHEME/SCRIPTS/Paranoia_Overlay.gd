extends Node2D

signal done

var _clicks

func _ready():
	set_process_input(false)

##
## Call this to start the sequence of screens displayed when the user suffers an
## attack of paranoia. The user clicks the mouse anywhere to pass from one
## screen to the next. When the last screen has been displayed, a done() signal
## will be emitted.
##
func start():
	_clicks = 0
	show()
	$Alert.play("Vibration")
	$On_Off.play("Appearance")
	set_process_input(true)

func _on_finished(_anim_name: StringName):
	set_process_input(false)
	$Alert.stop()
	hide()
	done.emit()

func _input(event: InputEvent):
	if not event.is_action_pressed("Left_Click") or $On_Off.is_playing():
		return
	_clicks += 1
	match _clicks:
		1:
			$On_Off.play("Disappearance")
		2:
			$On_Off.play("Final_Disappearance")
			$On_Off.animation_finished.connect(_on_finished, CONNECT_ONE_SHOT)
